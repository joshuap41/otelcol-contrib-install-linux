Overview

OTel Collector Contrib Installation script for linux platforms.



Notes for debugging:
- vsCode launch.json debug file notes

```bash
{
    // Use IntelliSense to learn about possible attributes.
    // Hover to view descriptions of existing attributes.
    // For more information, visit: https://go.microsoft.com/fwlink/?linkid=830387
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Debug Bash Script",
            "type": "bashdb",
            "request": "launch",
            "program": "/path/to/script/otel-install-script.sh",
            "args": [],
            "cwd": "/path/to/script",
        }
    ]
}
```

- Remove everything for testing

```bash
sudo yum remove -y  otelcol-contrib && sudo rm -r /etc/otelcol-contrib/ && sudo yum remove -y jq
```
