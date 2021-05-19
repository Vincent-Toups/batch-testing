rm explore-out.txt
az batch task delete --task-id exploration --job-id test-job --yes
az batch task create \
    --task-id exploration \
    --job-id test-job \
    --command-line 'echo az storage $(az storage)' | grep creationTime

sleep 3

az batch task file download \
   --task-id exploration \
   --job-id test-job \
   --destination ./explore-out.txt \
   --file-path stdout.txt
cat explore-out.txt
