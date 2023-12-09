export LD_LIBRARY_PATH=./:$LD_LIBRARY_PATH
./scripts/mojoc moxt_test.mojo -lmoxt -L . -o moxt_test
./moxt_test