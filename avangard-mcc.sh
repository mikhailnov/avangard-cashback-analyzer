#!/usr/bin/env bash

set -e

file="$1"
if ! test -r "$file" ; then
	echo "Укажите путь к файлу с выгрузкой в CSV первым аргументом, например: $0 file.csv"
	exit 1
fi

# Выводить ли попавшие под кешбек операции
PRINT_CASHEDBACK="${PRINT_CASHEDBACK:-0}"

# Не попадающие под кешбек MCC
# https://avangard.ru/rus/private/cards/exclbonusworld/
em=()
em+=(5814)
em+=(5300)
em+=(5399)
em+=(5921)
em+=(5411)
em+=(5964)
em+=(4900)
em+=(5511)
em+=(8211)
em+=(8220)
em+=(6513)
em+=(8011)
em+=(8021)
em+=(8031)
em+=(8041)
em+=(8042)
em+=(8043)
em+=(8049)
em+=(8050)
em+=(8062)
em+=(8071)
em+=(8398)
em+=(4112)
em+=(4814)
em+=(9399)
em+=(9222)
em+=(9223)
em+=(9311)
em+=(9402)
em+=(9211)

# сумма всех платежей
sum_total=0
# сумма платежей, попадающих под кешбек
# (дробную часть тупо отбрасываем для упрощения)
sum_total_cashedback=0
# не попадающих под кешбек
sum_total_not_cashedback=0

# сумма бонусных миль при кешбеке 1 миля за каждые целые 30 руб
miles_30_total=0
# 1 миля за целые 50 руб
miles_50_total=0
# 1 миля за целые 20 руб
miles_20_total=0

# кол-во операций, участвоваших в подсчете
ops_total=0
ops_total_cashedback=0
ops_total_not_cashedback=0

while read -r line
do
	[ -n "$line" ] || continue
	# извлекаем MCC-код
	IFS=';' read -r -a arr <<< "$line"
	mcc="${arr[8]}"
	# извлекаем сумму (округляем до целого)
	IFS='.' read -r -a arr <<< "${arr[6]}"
	sum="${arr[0]}"
	[ -n "$sum" ] || continue
	[ "$sum" -gt 0 ] || continue
	# проверяем, вход ли код платежа в список тех, по которым нет кешбека
	mcc_is_in_list=0
	for (( i = 0; i < ${#em[@]}; i++ ))
	do
		if [ "$mcc" = "${em[i]}" ]; then
			mcc_is_in_list=1
			break
		fi
	done
	if [ "$mcc_is_in_list" != 1 ]
	then
		sum_total_cashedback=$((sum_total_cashedback+sum))
		ops_total_cashedback=$((ops_total_cashedback+1))
		miles_30_total=$((miles_30_total+sum/30))
		miles_50_total=$((miles_50_total+sum/50))
		miles_20_total=$((miles_20_total+sum/20))
		if [ "$PRINT_CASHEDBACK" != 0 ]; then
			echo "$line"
		fi
	else
		sum_total_not_cashedback=$((sum_total_not_cashedback+sum))
		ops_total_not_cashedback=$((ops_total_not_cashedback+1))
	fi
	sum_total=$((sum_total+sum))
	ops_total=$((ops_total+1))
done < <(iconv -f cp1251 "$file" | sed -e 's,",,g')

echo "Всего: $sum_total руб, $ops_total операций"
echo "Попадает под кешбек: $sum_total_cashedback руб, $ops_total_cashedback операций"
echo "Не попадает под кешбек: $sum_total_not_cashedback руб, $ops_total_not_cashedback операций"
echo "Доля попавших под кешбек средств: $(echo "${sum_total_cashedback}/${sum_total}*100" | bc -lq)%"
echo "Доля попавших под кешбек операций: $(echo "${ops_total_cashedback}/${ops_total}*100" | bc -lq)%"
echo "Бонусных миль по тарифу 1 миля за каждые целые 30 руб.: ${miles_30_total}"
echo "Бонусных миль по тарифу 1 миля за каждые целые 50 руб.: ${miles_50_total}"
echo "Бонусных миль по тарифу 1 миля за каждые целые 20 руб.: ${miles_20_total}"
