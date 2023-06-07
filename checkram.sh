THRESHOLD=15

RAM_USAGE=$(free | awk '/^Mem/ {print int(($3/$2)*100)}')

if [ "$RAM_USAGE" -ge "$THRESHOLD" ]; then

    echo "Current ram usage $RAM_USAGE% is higher than $THRESHOLD%"
else
    echo "Current $RAM_USAGE% is under of $THRESHOLD%"
fi