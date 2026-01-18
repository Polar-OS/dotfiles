
main() {
	echo ""
	echo "$(upower -i $(upower -e | grep BAT) | grep --color=never -E "percentage|state" | awk '{print $2}')%"
}

main
