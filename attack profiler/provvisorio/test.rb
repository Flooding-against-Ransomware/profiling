def rimuovi_valori_comuni(json1, json2)
  # Ottieni i valori 'path' da json1
  path1_values = json1.map do |elemento|
    elemento['path'].is_a?(Array) ? elemento['path'] : []
  end.flatten

  # Rimuovi i valori comuni tra path1 e path2 da json2
  json2.each do |elemento|
    if elemento['path'].respond_to?(:delete_if)
      elemento['path'].delete_if { |valore| path1_values.include?(valore) }
    end
  end

  # Rimuovi gli elementi da json2 se 'path' diventa vuoto
  json2.reject! { |elemento| elemento['path'].nil? || elemento['path'].empty? }

  return json2
end



# Esempio di utilizzo
path1 = '{
  "data": [
    { "path": ["folder1/file1.txt", "folder2/file2.txt"] },
    { "path": ["folder3/file3.txt"] }
  ]
}'

path2 = '{
  "data": [
    { "path": ["folder1/file1.txt", "folder4/file4.txt"] },
    { "path": ["folder5/file5.txt"] }
  ]
}'

risultato = rimuovi_valori_comuni(path1, path2)
puts risultato