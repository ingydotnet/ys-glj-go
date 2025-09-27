ys-glj-go
=========

Test out Glojure AOT with a Clojure program that requires a Clojure library:

* `src/99-bottles.ys`
* `src/ys/v0.ys`

To test, run:
```
$ make test
```

This will:

* Compile YS to Clojure
* Compile Clojure to Glojure
* Compile Glojure to Go
* Compile Go to `99-bottles` binary
* Run the binary and print 3 verses
