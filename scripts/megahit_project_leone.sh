base=b5b8803602f6f05e66d4e737881ae177

/home/brettin/local/megahit-1.0.2/megahit -m 120000000000 --cpu-only -l 300 -o megahit-$base \
   --input-cmd "zcat *.gz" \
   --k-min 21 --k-max 99 --k-step 10 \
   --min-count 2 \
   --num-cpu-threads 24 \
   | tee Log
