#!/usr/bin/env bash
# gpu_eff_final_with_end.sh
# Usage: ./gpu_eff_final_with_end.sh [-p PARTITION] [-s STARTDATE] [-e ENDDATE]
# Output: CSV: user,avg_gpu_eff
set -euo pipefail

PARTITION="h200alloc"
STARTDATE="$(date -d 'today' +%Y-%m-%d)"
ENDDATE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -p|--partition) PARTITION="$2"; shift 2;;
    -s|--start) STARTDATE="$2"; shift 2;;
    -e|--end) ENDDATE="$2"; shift 2;;
    -h|--help) echo "Usage: $0 [-p PARTITION] [-s STARTDATE] [-e ENDDATE]"; exit 0;;
    *) echo "Unknown arg: $1"; exit 2;;
  esac
done

USERS=(
aap100 aba41 aep13 af375 ah670 bcp28 bj142 bl332 bmajoros bz144 ccc14 cd391 ch594 cw446 db501 dc460 dpb6 ds633 ds708 dz92 eb408 emf55 ew244 fl105 gk126 hc387 hdv2 hh285 hl385 hl542 hlapp hm218 hp83 jf381 jm688 jmnewton josh js1214 jt430 jx42 jz259 kap142 kd312 kdb77 kh504 kk319 kk338 kk405 ls542 ma642 mah148 mas296 me196 mlp6 mme4 mrl91 ms1008 mw467 nn115 np159 owzar001 par58 pl229 rh137 rm145 rs663 rt195 rv103 rz179 sao23 sb909 sc829 sib2 sk1045 sl904 sm996 ssp74 sw361 swhite sz343 tc319 tl363 tm103 ts415 ukh wac20 wc230 xc242 xg101 xg103 xj58 xw306 xy200 xz420 yb68 yc583 yd168 yh386 yh440 yj215 yl407 ym208 ys460 ys485 yw749 yx275 yx314 yz697 yz886 za66 zh127 zh202 zj67 zl310 zp70 zwb zy202
)

printf 'user,avg_gpu_eff\n'

# extract GPUEff from footer by header char positions
extract_from_footer_by_header() {
  local report="$1"
  # detect "No valid jobs found." (case-insensitive)
  if printf '%s\n' "$report" | awk 'BEGIN{IGNORECASE=1} /No valid jobs found/ { found=1 } END{exit !(found==1)}'; then
    echo "NO_VALID_JOBS"
    return
  fi

  # header line (first line that begins with "User" and has "JobID")
  header_line="$(printf '%s\n' "$report" | awk '/^User[[:space:]]+JobID/ { print; exit }')"
  weighted_line="$(printf '%s\n' "$report" | awk 'BEGIN{IGNORECASE=1} /WEIGHTED/ { line=$0 } END{ print line }')"

  if [[ -z "$weighted_line" ]]; then
    echo "NO_WEIGHTED"
    return
  fi
  if [[ -z "$header_line" ]]; then
    echo "NO_HEADER"
    return
  fi

  # find gpueff start position in header (1-based). If missing, fail.
  gpueff_pos=$(awk -v h="$header_line" 'BEGIN{print index(h,"GPUEff")}')
  if [[ -z "$gpueff_pos" || "$gpueff_pos" -eq 0 ]]; then
    echo "NO_GPUEFF_HEADER"
    return
  fi

  # find next field start after GPUEff by looking for candidates and picking the smallest index > gpueff_pos
  next_pos=0
  for token in "GPUUtil" "GPUMemEff" "GPUMem" "Partition" "User" "JobID"; do
    p=$(awk -v h="$header_line" -v t="$token" 'BEGIN{print index(h,t)}')
    if [[ "$p" -gt 0 && ( "$next_pos" -eq 0 || "$p" -lt "$next_pos" ) && "$p" -gt "$gpueff_pos" ]]; then
      next_pos=$p
    fi
  done
  if [[ "$next_pos" -eq 0 ]]; then
    header_len=$(printf '%s' "$header_line" | wc -c)
    next_pos=$((header_len + 1))
  fi

  start_index=$((gpueff_pos - 1))
  length=$(( next_pos - gpueff_pos ))
  # extract substring from weighted_line using cut (character positions)
  substr="$(printf '%s' "$weighted_line" | cut -c $((start_index+1))-$((start_index+length)) )"
  substr_trimmed="$(printf '%s' "$substr" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"

  # If substring explicitly contains '---', treat as ZERO per your request
  if printf '%s\n' "$substr_trimmed" | grep -q '^[-][-][-]$'; then
    echo "0"
    return
  fi

  # extract first percentage like token in the substring
  if [[ "$substr_trimmed" =~ ([0-9]+(\.[0-9]+)?)% ]]; then
    echo "${BASH_REMATCH[1]}"
    return
  fi
  # if no percent sign but numeric present, return numeric
  if [[ "$substr_trimmed" =~ ([0-9]+(\.[0-9]+)?) ]]; then
    echo "${BASH_REMATCH[1]}"
    return
  fi

  # if can't parse numeric but footer exists, return 0 (treat missing as zero)
  echo "0"
}

# fallback per-row aggregator (job-hours weighted, treat '---' as 0)
compute_from_rows() {
  local report="$1"
  awk '
  BEGIN { FS="[[:space:]]+"; weighted=0; hours_sum=0; rows=0 }
  /^User[[:space:]]+JobID/ || /^[-]+$/ || /^Processing/ { next }
  {
    rows++
    # find jobid index (first purely numeric)
    jobid_idx=0
    for(i=1;i<=NF;i++) if($i ~ /^[0-9]+$/){ jobid_idx=i; break }
    # find elapsed searching after jobid first, otherwise full line
    elapsed_idx=0
    if(jobid_idx>0){
      for(i=jobid_idx+1;i<=NF;i++) if(index($i,":")>0 || index($i,"-")>0){ elapsed_idx=i; break }
    }
    if(elapsed_idx==0){
      for(i=1;i<=NF;i++) if(index($i,":")>0 || index($i,"-")>0){ elapsed_idx=i; break }
    }
    if(elapsed_idx==0 && NF>=4 && $4 ~ /^[0-9]+(:[0-9]{2}(:[0-9]{2})?)?$/) elapsed_idx=4
    elapsed_tok = (elapsed_idx>0 ? $(elapsed_idx) : "")
    # gather pct-like tokens after elapsed
    pct_count=0; delete pcts
    if(elapsed_idx>0){
      for(j=elapsed_idx+1;j<=NF;j++){
        tok=$(j)
        if(tok=="---" || tok ~ /^[0-9]+(\.[0-9]+)?%?$/){ pct_count++; pcts[pct_count]=tok }
      }
    }
    gpueff_tok = (pct_count>=4 ? pcts[4] : "---")
    if(gpueff_tok=="" || gpueff_tok=="---"){ gpval=0 } else { g=gpueff_tok; gsub("%","",g); gsub(",","",g); gpval = (g ~ /^[0-9]+(\.[0-9]+)?$/ ? g+0.0 : 0) }
    # parse elapsed
    secs=0
    if(elapsed_tok!=""){
      tm=elapsed_tok; days=0
      if(index(tm,"-")>0){ split(tm,parts,"-"); days=parts[1]+0; tm=parts[2] }
      split(tm,t,":")
      if(length(t)==3) secs = t[1]*3600 + t[2]*60 + t[3]
      else if(length(t)==2) secs = t[1]*60 + t[2]
      else secs = tm + 0
      secs += days*24*3600
    }
    h = secs/3600.0
    if(h>0){ weighted += gpval * h; hours_sum += h }
  }
  END { if(hours_sum>0) printf "%.4f", weighted/hours_sum; else print "NA" }
  ' <<< "$report"
}

# iterate users
for u in "${USERS[@]}"; do
  # build slurm-report command with optional end date
  if [[ -n "$ENDDATE" ]]; then
    report="$(slurm-report -r "$PARTITION" --starttime "$STARTDATE" --endtime "$ENDDATE" --user "$u" --plain 2>/dev/null || true)"
  else
    report="$(slurm-report -r "$PARTITION" --starttime "$STARTDATE" --user "$u" --plain 2>/dev/null || true)"
  fi

  # if report empty -> NA
  if [[ -z "$report" ]]; then
    printf '%s,NA\n' "$u"
    continue
  fi

  # If report explicitly says "No valid jobs found." -> NA
  if printf '%s\n' "$report" | awk 'BEGIN{IGNORECASE=1} /No valid jobs found/ { found=1 } END{exit !(found==1)}'; then
    printf '%s,NA\n' "$u"
    continue
  fi

  # Try footer extraction
  val="$(extract_from_footer_by_header "$report")"
  if [[ "$val" == "NO_WEIGHTED" || "$val" == "NO_HEADER" || "$val" == "NO_GPUEFF_HEADER" ]]; then
    # fallback: compute from rows (treating --- as 0)
    val="$(compute_from_rows "$report")"
    # ensure numeric or NA
    if [[ -z "$val" ]]; then val="NA"; fi
    printf '%s,%s\n' "$u" "$val"
    continue
  fi

  # If footer extraction returned a numeric string (or 0) print it; otherwise if special token, handle
  case "$val" in
    NO_VALID_JOBS)
      printf '%s,NA\n' "$u";;
    NO_VALUE)
      printf '%s,0\n' "$u";;
    *)
      # val should be numeric or "0"
      printf '%s,%s\n' "$u" "$val";;
  esac
done

exit 0
