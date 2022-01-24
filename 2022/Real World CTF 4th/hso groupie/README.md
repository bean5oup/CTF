# hso groupie

`Clone-and-Pwn`, `difficulty:hard`

Solved by 2 Teams

---

Help check how secure our latest PaaS (Pdftohtml-as-a-Service) is!

Pick your favorite bug from this bloody list, or really, just exploit that bug so your exploit would also work on latest Poppler [1] and maybe even KItinerary.

The container image is also available on Docker Hub.

[1] Yeah, turns out propagating bug fixes between different Clone-and-Own codebases takes time :)

```
socat -t90 stdio tcp-connect:47.242.147.191:31337
```