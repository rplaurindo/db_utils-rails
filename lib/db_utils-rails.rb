# adicionar $LOAD_PATH e dar require nos arquivos .rb

require "byebug"

module DBUtils
  include Rails
  ROOT_PATH = File.expand_path "../../", __FILE__

  # Com a classe Railtie não funcionou
  # ver questão do initialize
  Application.rake_tasks do
    # não se pode dar require em um arquivo que não é ruby ou que faz parte de biblioteca padrão do sistema, como .so ou .dll
    # mapear tasks em diretórios e subdiretórios e dar load em todas
    load File.join(ROOT_PATH, "/lib/tasks/active_record/railties/databases.rake")
  end

end
