redistop.rb
============

### Without any performance impact
```
$ redis-benchmark -p 6380 -c 10 -n 10000 -q -t set,get
SET: 22727.27 requests per second
GET: 23201.86 requests per second
MSET (10 keys): 16528.93 requests per second
```

### With MONITOR
```
$ redis-cli -p 6380 monitor >/dev/null
```
Another console:
```
$ redis-benchmark -p 6380 -c 10 -n 10000 -q -t set,get
SET: 17793.60 requests per second
GET: 16447.37 requests per second
MSET (10 keys): 13698.63 requests per second
```

### With redistop.rb
```
~$ ruby redistop.rb -F
Probing...Type CTRL+C to stop probing.

PID   COUNT LATENCY     CMD
1794  925   <0.000023>  zrangebyscore
2068  324   <0.000032>  zrangebyscore
22463 293   <0.000033>  get
53680 255   <0.000014>  get
53680 252   <0.000017>  hget
1794  249   <0.000015>  get
1794  248   <0.000018>  hget
22463 230   <0.000039>  hget
1747  225   <0.000053>  zrangebyscore
2068  179   <0.000018>  hget
```
Another console:
```
$ redis-benchmark -p 6380 -c 10 -n 10000 -q -t set,get
SET: 19685.04 requests per second
GET: 18691.59 requests per second
MSET (10 keys): 15772.87 requests per second
```
