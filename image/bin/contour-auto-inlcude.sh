#! /bin/sh
##
## contour-auto-inlcude.sh --
##
##
## Commands;
##

prg=$(basename $0)
dir=$(dirname $0); dir=$(readlink -f $dir)
tmp=/tmp/${prg}_$$

die() {
    echo "ERROR: $*" >&2
    rm -rf $tmp
    exit 1
}
help() {
    grep '^##' $0 | cut -c3-
    rm -rf $tmp
    exit 0
}
test -n "$1" || help
echo "$1" | grep -qi "^help\|-h" && help

log() {
	echo "$prg: $*" >&2
}
dbg() {
	test -n "$__verbose" && echo "$prg: $*" >&2
}

##  env
##    Print environment.
##
cmd_env() {
	test "$cmd" = "env" && set | grep -E '^(__.*|ARCHIVE)='
	test -n "$__namespace" || __namespace=default
	test -n "$__prefix" || __prefix=example.com/
}

##  get_path_objects [--namespace=default] <parent>
##    Get path objects for a parent.
cmd_get_path_objects() {
	test -n "$1" || die 'No parent'
	cmd_env
	kubectl -n $__namespace get httpproxy -l ${__prefix}parent=$1 -o name | \
		cut -d / -f2
}

##  get_top_objects
##    Get top objects from all namespaces in form "namespace/name".
cmd_get_top_objects() {
	cmd_env
	mkdir -p $tmp
	kubectl get httpproxy -A -l ${__prefix}vhost=yes -o json > $tmp/out
	jq -r '.items[].metadata| "\(.namespace)/\(.name)"' < $tmp/out
}

##  emit_include_list [--namespace=default] <top-object>
##    Emit an "includes:" array for a given top-object
cmd_emit_include_list() {
	test -n "$1" || die 'No top-object'
	cat <<EOF
spec:
  includes:
EOF
	local n
	for n in $(cmd_get_path_objects $1); do
		echo "    - name: $n"
	done
}

##
##  update [--interval=<secons>]
##    Update the "includes:" array in all vhost objects.
##    If --interval is specified this command will not return but update
##    continuously with the given interval.
##
cmd_update() {
	if test -n "$__interval"; then
		while true; do
			update
			sleep $__interval
		done
	fi
	update
}
update() {
	local top n f
	mkdir -p $tmp
	f=$tmp/include.yaml
	for top in $(cmd_get_top_objects); do
		__namespace=$(echo $top | cut -d / -f1)
		n=$(echo $top | cut -d / -f2)
		cmd_emit_include_list $n > $f
		kubectl -n $__namespace patch httpproxy $n --type merge --patch "$(cat $f)"
	done
}



# Get the command
cmd=$1
shift
grep -q "^cmd_$cmd()" $0 $hook || die "Invalid command [$cmd]"

while echo "$1" | grep -q '^--'; do
    if echo $1 | grep -q =; then
	o=$(echo "$1" | cut -d= -f1 | sed -e 's,-,_,g')
	v=$(echo "$1" | cut -d= -f2-)
	eval "$o=\"$v\""
    else
	o=$(echo "$1" | sed -e 's,-,_,g')
	eval "$o=yes"
    fi
    shift
done
unset o v
long_opts=`set | grep '^__' | cut -d= -f1`

# Execute command
trap "die Interrupted" INT TERM
cmd_$cmd "$@"
status=$?
rm -rf $tmp
exit $status
