=begin

 * Copyright 2025 (C) by Saverio Giallorenzo <saverio.giallorenzo@gmail.com>  *
 * and Simone Melloni <melloni.simone@gmail.com>                              *
 *                                                                            *
 * This program is free software; you can redistribute it and/or modify       *
 * it under the terms of the GNU Library General Public License as            *
 * published by the Free Software Foundation; either version 2 of the         *
 * License, or (at your option) any later version.                            *
 *                                                                            *
 * This program is distributed in the hope that it will be useful,            *
 * but WITHOUT ANY WARRANTY; without even the implied warranty of             *
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              *
 * GNU General Public License for more details.                               *
 *                                                                            *
 * You should have received a copy of the GNU Library General Public          *
 * License along with this program; if not, write to the                      *
 * Free Software Foundation, Inc.,                                            *
 * 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.                  *
 *                                                                            *
 * For details about the authors of this software, see the AUTHORS file.      *

 *  Ranflood - https://ranflood.netlify.app/                                  *

=end

require 'json'


def crea_struct(file_path)
  risultato = {}

  # Leggi il contenuto del file JSON
  json_content = File.read(file_path)
  data = JSON.parse(json_content)

  # Per ogni elemento
  data.each do |elemento|
    # Estrai il percorso e l'hash dall'elemento
    percorso = elemento[ "path" ]
    hash = elemento[ "checksum" ]

    # Aggiungi l'elemento alla struttura
    risultato[hash] ||= []  # Inizializza l'array se non esiste già
    risultato[hash] << percorso
  end

  return risultato
end

def unisci_strutture(struttura1, struttura2)
  risultato = {}

  # Unisce i dati dalla struttura 1
  struttura1.each do |hash, path1|
    info = { :original => path1.first, :status => "", :replicas => [] }
    
    # L'hash esiste anche nella struttura 2 ?
    if struttura2.key?(hash)
      path2 = struttura2[hash]

      # Il percorso di path1 è presente anche in path2, allora il file è intonso
      # altrimenti è una replica
      if path2.include?(path1.first)        
        info[ :status ] = "pristine"
        info[ :replicas ] = path2 - path1 # Aggiungo le repliche ma tolgo il percorso originale, che potrò dedurre dalla struttura del JSON
      else
        info[ :status ] = "replica"
        info[ :replicas ] = path2
      end
    else
      # L'hash non esiste nella struttura 2, quindi il file è perduto
      info[ :status ] = "lost"
    end

    risultato[ hash ] = info
  end

  # Aggiungo le info dalla struttura 2
  struttura2.each do |hash, path2|
    unless risultato.key?(hash)
      # L'hash non esiste nella struttura 1
      risultato[hash] = {
        :original => "",
        :status => "replica",
        :replicas => path2
      }
    end
  end

  return risultato
end


def crea_albero(input_hash)

  output_hash = { :files => {} , :folders  =>  {} }

  input_hash.each do |hash, info|
    original_path = info[ :original ]
    status = info[ :status ]
    replicas = info[ :replicas ]

    # Estrai il nome del file dalla path
    file_name = File.basename( original_path )

    # Divide la path in cartelle
    path_parts = File.dirname( original_path ).split("/")

    # Inizializza la struttura se non esiste
    current_folder = output_hash[ :folders ]

    # Verifico se il percorso contiene il carattere "/", es non lo contiene è nella root
    if original_path.include?( "/" )
      # current_folder = output_hash["folders"]
      path_parts.each do | folder |
        current_folder[ folder ] ||= { :folders => {} }
        current_folder = current_folder[ folder ][ :folders ]
      end

      current_folder[ :files ] ||= {}
      # Aggiungi il file corrente
      current_folder[ :files ][file_name] = {
        :name => file_name,
        :checksum => hash,
        :status => status,
        :replicas => replicas
      }
    else

      current_folder = output_hash[ :files ]
      current_folder ||= {}
      # Aggiungi il file corrente
      current_folder[file_name] = {
        :name => file_name,
        :checksum => hash,
        :status => status,
        :replicas => replicas
      }
    end
  end

  return output_hash
end

# sposta di un livello in alto "files" nel JSON
def organizza_files(struct_albero)
  result = {}

  # alzo di un lvl tutti i "files"
  struct_albero.each do |key, value|
    if value.is_a?(Hash) && value.key?( :folders ) && value[ :folders ].key?( :files )
      files = value[ :folders ].delete( :files )
      value[ :files ] = files
    end
    
    result[key] = value.is_a?(Hash) ? organizza_files(value) : value
  end 

  result
end

def salva_json(albero, nome_file_output)
  albero = JSON.pretty_generate(albero)
  File.open(nome_file_output, 'w') do |file|
    file.puts(albero)
  end
end

if ARGV.length != 2
  puts "Usage: ruby attack_profiler.rb <file_input1> <file_input2>"
  exit(1)
end

file_input_1 = ARGV[0]
file_input_2 = ARGV[1]

directory = File.dirname(file_input_2)
nome_file_senza_estensione = File.basename(file_input_2, File.extname(file_input_2))
nome_file_nuovo = "#{nome_file_senza_estensione}-report.json"

nome_file_output = File.join(directory, nome_file_nuovo);

struct_base = crea_struct(file_input_1)
# puts struct_base
# puts "-----------------------"
struct_contrasto = crea_struct(file_input_2)
# puts struct_contrasto

# puts "-----------------------"

struct_risultato = unisci_strutture(struct_base, struct_contrasto)
# puts struct_risultato

# elaborazione dell'hash in albero cartelle - file
struct_albero = crea_albero(struct_risultato)

# estraggo il nome file dal percorso e poi lo divido per recuperare i parametri del test: 
nome_file_2_split = File.basename(file_input_2).split('-')
parametri_test = {  
  "ransomware"  => ->(x){ x[x.size-1] }.call( nome_file_2_split[0].split('/') ), 
  "ranflood_delay"  =>  nome_file_2_split[1] || 'none', 
  "strategy"  =>  nome_file_2_split[2] || 'none',
  "root" => "C:/users/IEuser",
}


# sposto tutte le chiavi "files" di un livello in alto in modo da rispettare il formato desiderato
struct_albero_JSON = organizza_files(struct_albero)

# unisco i due hash info test  e albero cartelle
struct_albero_JSON = parametri_test.merge(struct_albero_JSON)

salva_json(struct_albero_JSON, nome_file_output)

puts "Albero delle directory salvato in #{nome_file_output}"
