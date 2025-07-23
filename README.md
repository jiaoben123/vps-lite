Paste to run:   

```
curl -Ls https://raw.githubusercontent.com/DuolaD/vps-lite/main/clean.sh -o clean.sh && chmod +x clean.sh && ./clean.sh
```

Uninstall:

```
crontab -l | grep -v 'vps-lite-daily-clean.sh' | crontab -
```
