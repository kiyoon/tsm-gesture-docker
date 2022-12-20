```
docker run --gpus all -it --device=/dev/video0:/dev/video0 -e DISPLAY=${DISPLAY} -v /tmp/.X11-unix:/tmp/.X11-unix kiyoon/tsm-gesture
```
