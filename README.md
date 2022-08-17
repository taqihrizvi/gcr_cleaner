# GCR-Cleaner
The script uses the gcloud container images list command to first retrieve all images within the stated repository.

It then uses gcloud container images list-tags to get all digests for the images, ordered by timestamp created.

Assuming the latest 3 images might be useful for rollbacks etc the script keeps those around, deleting all other images with gcloud container images delete.