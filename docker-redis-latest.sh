docker run -p 6380:6380 \
    -v ./redis/tls/redis.key:/etc/ssl/private/redis.key \
    -v ./redis/tls/redis.crt:/etc/ssl/certs/redis.crt \
    -v ./redis/tls/ca.crt:/etc/ssl/certs/ca.crt \
    -v ./redis/redis.conf:/usr/local/etc/redis/redis.conf \
    redis:latest \
    redis-server /usr/local/etc/redis/redis.conf
