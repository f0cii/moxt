export LD_LIBRARY_PATH=./:$LD_LIBRARY_PATH
./scripts/mojoc moxt_test.mojo -lmo -L . -o moxt_test
./moxt_test