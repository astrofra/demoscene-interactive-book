ffmpeg -i caillou.mov -vf "select='not(mod(n,3))',setpts=N/FRAME_RATE/TB" -vsync vfr caillou/frame_%%04d.png
pause
