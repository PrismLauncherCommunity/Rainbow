package main

import (
    "fmt"
    "log"
    "net/http"
    "os"
    "os/exec"
    "time"
)

func main() {
    go func() {
        time.Sleep(time.Second)
        cmd := exec.Command("java", "-jar", "packwiz-installer-bootstrap.jar", "-g", "-s", "server", fmt.Sprintf("http://0.0.0.0:8080/%s/pack.toml", os.Args[1]))
        cmd.Dir = "build/server"
        cmd.Stdout = os.Stdout
        cmd.Stderr = os.Stderr
        if err := cmd.Run(); err != nil {
            panic(err)
        }
        os.Exit(0)
    }()
    log.Fatal(http.ListenAndServe(":8080", http.FileServer(http.Dir("pack"))))
}