package main

import (
	"log"
	"os"
)

var (
	secret        = os.Getenv("SECRET")
	environSecret = os.Getenv("ENVIRONMENT_SECRET")
	ilog          = log.New(os.Stdout, "INFO: ", log.Ldate|log.Ltime|log.Lshortfile)
)

func main() {
	ilog.Printf("Environment Secret: %s, Decrypted Secret: %s\n", environSecret, secret)
}
