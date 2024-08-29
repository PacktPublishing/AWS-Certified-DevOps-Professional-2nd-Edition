package main

import (
	"fmt"
	"net/http"

	"golang.org/x/text/cases"
	"golang.org/x/text/language"
)

func main() {
	http.ListenAndServe("0.0.0.0:8080", http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte(sayHello(r.URL.Query().Get("name"))))
	}))
}

func sayHello(name string) string {
	if name == "" {
		return "Hello World!"
	}

	return fmt.Sprintf("Hello %s!", cases.Title(language.English, cases.Compact).String(name))
}
