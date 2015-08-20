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
Probing...Type CTRL+C to stop probing.

Total: 210 req/s

Most used functions:
7086  143 <0.000023>  zrangebyscore
7086  24  <0.000032>  zrevrangebyscore
7086  10  <0.000033>  zrem
7086  9 <0.000015>  zcard
7086  9 <0.000016>  zrange
7086  3 <0.000005>  ping
7086  3 <0.000034>  zincrby

Most used keys:
zrangebyscore                                      143
zrevrangebyscore                                   24
usr-353729-size                                    15
pbs-353729                                         12
usr-197938                                         12
```
Another console:
```
$ redis-benchmark -p 6380 -c 10 -n 10000 -q -t set,get
SET: 19685.04 requests per second
GET: 18691.59 requests per second
MSET (10 keys): 15772.87 requests per second
```
