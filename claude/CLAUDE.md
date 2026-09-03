## Bash paths

Bash already runs in the session working directory: pass every file and directory argument as an absolute path instead of prefixing a `cd`. With Read deny rules in settings.json, a relative path after a `cd` cannot be resolved by the permission classifier, and every grep, rg, diff, or git call in that shape prompts for manual approval.
