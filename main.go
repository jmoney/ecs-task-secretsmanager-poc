package main

import (
	"os"
	"log"
)

var (
	secret = os.Getenv("SECRET")
	ilog = log.New(os.Stdout, "INFO: ", log.Ldate|log.Ltime|log.Lshortfile)
)

func main() {
	ilog.Printf("Secret: %s\n", secret)
}