package main

import (
	"context"
	"crypto/tls"
	"fmt"
	"log/slog"
	"os"
	"strconv"
	"time"

	"github.com/redis/go-redis/v9"
)

func main() {
	logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
		AddSource: true,
		Level:     slog.LevelInfo,
	}))
	slog.SetDefault(logger)

	ctx := context.Background()

	redisHost := os.Getenv("REDIS_HOST")
	redisPort := os.Getenv("REDIS_PORT")
	redisPassword := os.Getenv("REDIS_PASSWORD")
	numItems := os.Getenv("NUM_ITEMS")

	redisHostAndPort := fmt.Sprintf("%s:%s", redisHost, redisPort)

	slog.Info("connecting to Redis", "host", redisHost, "port", redisPort)

	op := &redis.Options{Addr: redisHostAndPort, Password: redisPassword, TLSConfig: &tls.Config{MinVersion: tls.VersionTLS12}}
	client := redis.NewClient(op)

	max, err := strconv.Atoi(numItems)
	if err != nil {
		slog.Error("error casting string to int", "error", err)
	}

	msg := fmt.Sprintf("starting test at %s", time.Now())
	slog.Info(msg)

	for i := 0; i <= max; i++ {
		go push(ctx, *client, "jobs", i)
		
		if i%1000 == 0 {
			msg = fmt.Sprintf("%d jobs queued at %s", i, time.Now())
			slog.Info(msg)
		}

	}

	msg = fmt.Sprintf("completed test at %s", time.Now())
	slog.Info(msg)
}

func push(ctx context.Context, cl redis.Client, queue string, value interface{}) {
	err := cl.RPush(ctx, queue, value).Err()
	if err != nil {
		slog.Error("error pushing to Redis queue", "queue", queue, "error", err)
	}
}

func pop(ctx context.Context, cl redis.Client, queue string) {
	item, err := cl.RPop(ctx, queue).Result()
	if err != nil {
		slog.Error("error reading from queue", "error", err)
		return
	}
	slog.Info("read item from queue", "value", item)
}
