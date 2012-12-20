#!/bin/sh

# Run Wired Tiger Level DB benchmark.
# Assumes that a pre-built Wired Tiger library exists in ../wiredtiger.
# Assumes that the Wired Tiger build is shared, not static.
# but works if it is static.

BASHO_PATH="../basho.leveldb"
BDB_PATH="../db-5.3.21/build_unix"
MDB_PATH="../mdb/libraries/liblmdb"
SNAPPY_PATH="ext/compressors/snappy/.libs/"
WT_PATH="../wiredtiger/build_posix"

test_compress()
{
	if [ ! -e "$WT_PATH/$SNAPPY_PATH/libwiredtiger_snappy.so" ]; then
		echo "Snappy compression not included in Wired Tiger."
		echo "Could not find $WT_PATH/$SNAPPY_PATH/libwiredtiger_snappy.so"
		echo `$WT_PATH/$SNAPPY_PATH/`
		exit 1
	fi
}

if [ `uname` == "Darwin" ]; then
	basholib_path="DYLD_LIBRARY_PATH=$BASHO_PATH:"
	bdblib_path="DYLD_LIBRARY_PATH=$BDB_PATH/.libs:"
	levellib_path="DYLD_LIBRARY_PATH=.:"
	mdblib_path="DYLD_LIBRARY_PATH=$MDB_PATH:"
	wtlib_path="DYLD_LIBRARY_PATH=$WT_PATH/.libs:$WT_PATH/$SNAPPY_PATH"
else
	basholib_path="LD_LIBRARY_PATH=$BASHO_PATH:"
	bdblib_path="LD_LIBRARY_PATH=$BDB_PATH/.libs:"
	levellib_path="LD_LIBRARY_PATH=.:"
	mdblib_path="LD_LIBRARY_PATH=$MDB_PATH:"
	wtlib_path="LD_LIBRARY_PATH=$WT_PATH/.libs:$WT_PATH/$SNAPPY_PATH"
fi

#
# Test to run is one of (default big):
# small - 4Mb cache (or 6Mb, smallest WT can use), no other args.
# big|large - 128Mb cache,
# val - 4Mb cache (or 6Mb for WT), 100000 byte values, limit to 10000 items.
# bigval - 512Mb cache, 100000 byte values, limit to 4000 items.
#
# It runs the op that is in force at the time it finds the db to run.
# So, an example would be:
# run.sh wt lvl bdb
# run.sh small wt lvl bdb
# run.sh bigval wt lvl
#
mb128=134217728
mb512=536870912
origbenchargs="--cache_size=$mb128"
mdb_benchargs=""
mb4="4194304"
mb4wt="6537216"
smallrun="no"
op="big"
fdir="./DATA"
count=3
# The first arg may be the operation type.
while :
	do case "$1" in
	small)
		smallrun="yes"
		origbenchargs=""
		op="small"
		shift;;
	big|large)
		smallrun="no"
		origbenchargs="--cache_size=$mb128"
		op="big"
		shift;;
	bigval)
		smallrun="no"
		origbenchargs="--cache_size=$mb512 --value_size=100000 --num=4000"
		op="bigval"
		shift;;
	val|smval)
		smallrun="yes"
		origbenchargs="--value_size=100000 --num=10000"
		op="val"
		shift;;
	1|2|3|4|5|6|7|8|9)
		count=$1
		shift;;
	*)
		break;;
	esac
done

# Now that we have the operation to run, do so on all remaining DB types.
benchargs=$origbenchargs
while :
	do case "$1" in
	basho)
		fname=basho
		libp=$basholib_path
		prog=./db_bench_basho
		test "$smallrun" == "yes" && {
			benchargs="$origbenchargs --cache_size=$mb4"
		}
		shift;;
	bashos|bashosymas)
		fname=bosymas
		libp=$basholib_path
		prog=./db_bench_bashosymas
		test "$smallrun" == "yes" && {
			benchargs="$origbenchargs --cache_size=$mb4"
		}
		shift;;
	bdb)
		fname=bdbsymas
		libp=$bdblib_path
		prog=./db_bench_bdb
		test "$smallrun" == "yes" && {
			benchargs="$origbenchargs --cache_size=$mb4"
		}
		shift;;
	ldb|leveldb|lvldb|lvl)
		fname=lvl
		libp=$levellib_path
		prog=./db_bench
		test "$smallrun" == "yes" && {
			benchargs="$origbenchargs --cache_size=$mb4"
		}
		shift;;
	ldbs|leveldbs|lvldbs|lvls)
		fname=lvlsymas
		libp=$levellib_path
		prog=./db_bench_leveldb
		test "$smallrun" == "yes" && {
			benchargs="$origbenchargs --cache_size=$mb4"
		}
		shift;;
	mdb)
		fname=mdb
		libp=$mdblib_path
		prog=./db_bench_mdb
		benchargs="$mdbbenchargs"
		shift;;
	mdbs|mdbsymas)
		fname=mdbsymas
		libp=$mdblib_path
		prog=./db_bench_mdbsymas
		benchargs="$mdbbenchargs"
		shift;;
	wt|wiredtiger|wtl|wtlsm)
		fname=wtlsm
		libp=$wtlib_path
		prog=./db_bench_wiredtiger
		test "$smallrun" == "yes" && {
			benchargs="$origbenchargs --cache_size=$mb4wt"
		}
		test_compress
		shift;;
	wtp|wtpfx|wtlsmp)
		fname=wtlsmpfx
		libp=$wtlib_path
		prog=./db_bench_wiredtiger
		benchargs="$origbenchargs --nopfx"
		test "$smallrun" == "yes" && {
			benchargs="$benchargs --cache_size=$mb4wt"
		}
		test_compress
		shift;;
	wtb|wiredtigerb)
		fname=wtbtree
		libp=$wtlib_path
		prog=./db_bench_wiredtiger
		benchargs="$origbenchargs --use_lsm=0"
		test "$smallrun" == "yes" && {
			benchargs="$benchargs --cache_size=$mb4wt"
		}
		test_compress
		shift;;
	wtbp|wtbpfx)
		fname=wtbtreepfx
		libp=$wtlib_path
		prog=./db_bench_wiredtiger
		benchargs="$origbenchargs --use_lsm=0 --nopfx"
		test "$smallrun" == "yes" && {
			benchargs="$benchargs --cache_size=$mb4wt"
		}
		test_compress
		shift;;
	wts|wtsymas)
		fname=wtsymas
		libp=$wtlib_path
		prog=./db_bench_wtsymas
		test "$smallrun" == "yes" && {
			benchargs="$origbenchargs --cache_size=$mb4wt"
		}
		shift;;
	*)
		break;;
	esac
	# If we have a command to execute do so.
	if test -e $prog; then
		i=0
		while test "$i" != "$count" ; do
			name=$fdir/$op.$$.$i.$fname
			echo "Benchmark output in $name"
			time env "$libp" $prog $benchargs > $name
			i=`expr $i + 1`
		done
	else
		echo "Skipping, $prog is not built."
	fi
done
