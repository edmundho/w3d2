require 'singleton'
require 'sqlite3'

class QuestionsDatabase < SQLite3::Database
  include Singleton
  
  def initialize
    super('questions.db')
    self.type_translation = true
    self.results_as_hash = true
  end
end

class User
  def self.all
    users = QuestionsDatabase.instance.execute("SELECT * FROM users")
    users.map { |user_datum| User.new(user_datum) }
  end
  
  def self.find_by_name(fname, lname)
    
  end
  
  def initialize(options)
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end
  
  def create
    raise "#{self} already exists" if @id
    user_data = QuestionsDatabase.instance.execute(<<-SQL, @fname, @lname)
      INSERT INTO
        users (fname, lname)
      VALUES
        (?, ?)
    SQL
    @id = QuestionsDatabase.instance.last_insert_row_id
  end
  
  def update
    raise "#{self} does not exist" unless @id
    QuestionsDatabase.instance.execute(<<-SQL, @fname, @lname, @id)
    UPDATE 
      users 
    SET 
      fname = ?,
      lname = ?
    WHERE 
      id = ?
    SQL
  end
end

class Question 
  def self.all 
    q_data = QuestionsDatabase.instance.execute("SELECT * FROM questions")
    q_data.map {|q_datum| Question.new(q_datum)}
  end
  
  def self.find_by_author_id(author_id)
    q_data = QuestionsDatabase.instance.execute(<<-SQL, author_id)
      SELECT
        *
      FROM
        questions
      WHERE
        author_id = ?
    SQL
  end
  
  def initialize(options)
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @author_id = options['author_id']
  end
  
  def create
    raise "#{self} already exists" if @id
    QuestionsDatabase.instance.execute(<<-SQL, @title, @body, @author_id)
      INSERT INTO 
        questions (title, body, author_id)
      VALUES
        (?,?,?)
    SQL
    @id = QuestionsDatabase.instance.last_insert_row_id
  end
  
  def update
    raise "#{self} does not exist" unless @id
    QuestionsDatabase.instance.execute(<<-SQL, @title, @body, @author_id, @id)
    UPDATE 
      questions 
    SET 
      title= ?,
      body = ?,
      author_id = ?
    WHERE 
      id = ?
    SQL
  end
end

class Reply 
  def self.all 
    q_data = QuestionsDatabase.instance.execute("SELECT * FROM replies")
    q_data.map {|q_datum| Question.new(q_datum)}
  end
  
  def self.find_by_user_id(user_id)
    r_data = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        *
      FROM
        replies
      WHERE
        user_id = ?
    SQL
  end
  
  def self.find_by_question_id(question_id)
    r_data = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        *
      FROM
        replies
      WHERE
        question_id = ?
    SQL
  end  
  
  def initialize(options)
    @id = options['id']
    @question_id = options['question_id']
    @user_id = options['user_id']
    @parent_id = options['parent_id']
    @body = options['body']
  end
  
  def create
    raise "#{self} already exists" if @id
    QuestionsDatabase.instance.execute(<<-SQL, @question_id, @user_id, @parent_id, @body)
      INSERT INTO 
        questions (question_id, user_id, parent_id, body)
      VALUES
        (?,?,?, ?)
    SQL
    @id = QuestionsDatabase.instance.last_insert_row_id
  end
  
  def update
    raise "#{self} does not exist" unless @id
    QuestionsDatabase.instance.execute(<<-SQL, @question_id, @user_id, @parent_id, @body)
    UPDATE 
      questions 
    SET 
      question_id = ?,
      user_id = ?,
      parent_id = ?,
      body = ?
    WHERE 
      id = ?
    SQL
  end
end

class Like
  
end