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
    name = QuestionsDatabase.instance.execute(<<-SQL)
    SELECT
     * 
     FROM 
     users 
     WHERE fname = ? AND lname = ?
     SQL
     name.map { |user_datum| User.new(user_datum) }
  end
  
  def initialize(options)
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end
  
  def average_karma
    
  end
  
  def followed_questions
    QuestionFollow.followed_questions_for_user_id(@id)
  end
  
  def authored_questions
    Question.find_by_author_id(@id)
  end
  
  def authored_replies
    Reply.find_by_user_id(@id)
  end
  
  def liked_questions
    liked_questions_for_user_id(@id)
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
    q_data.map {|q_datum| Question.new(q_datum)}
  end
  
  def self.most_followed(n)
    QuestionFollow.most_followed_questions(n)
  end
  
  def self.most_liked(n)
    QuestionLike.most_liked_questions(n)
  end
  
  def initialize(options)
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @author_id = options['author_id']
  end
  
  def likers
    QuestionLike.likers_for_question_id(@id)
  end
  
  def num_likes
    QuestionLike.num_likes_for_question_id(@id)
  end
  
  def followers
    QuestionFollow.followers_for_question_id(@id)
  end
  
  def author
    @author_id
  end
  
  def replies
    Reply.find_by_question_id(@id)
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
    q_data.map {|q_datum| Reply.new(q_datum)}
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
    r_data.map {|q_datum| Reply.new(q_datum)}
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
    r_data.map {|q_datum| Reply.new(q_datum)}
  end  
  
  def initialize(options)
    @id = options['id']
    @question_id = options['question_id']
    @user_id = options['user_id']
    @parent_id = options['parent_id']
    @body = options['body']
  end
  
  def author
    @user_id
  end
  
  def question
    @question_id
  end
  
  def parent_reply
    @parent_id
  end
  
  def child_replies
    children = QuestionsDatabase.instance.execute(<<-SQL, @id, @question_id)
      SELECT
        *
      FROM 
        replies
      WHERE
        parent_id = ? AND question_id = ?
    SQL
    children.map { |child| Reply.new(child) }
  end
  
  def create
    raise "#{self} already exists" if @id
    QuestionsDatabase.instance.execute(<<-SQL, @question_id, @user_id, @parent_id, @body)
      INSERT INTO 
        replies (question_id, user_id, parent_id, body)
      VALUES
        (?,?,?, ?)
    SQL
    @id = QuestionsDatabase.instance.last_insert_row_id
  end
  
  def update
    raise "#{self} does not exist" unless @id
    QuestionsDatabase.instance.execute(<<-SQL, @question_id, @user_id, @parent_id, @body)
    UPDATE 
      replies 
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













class QuestionFollow
  def self.all 
    q_data = QuestionsDatabase.instance.execute("SELECT * FROM questions_follows")
    q_data.map {|q_datum| QuestionFollow.new(q_datum)}
  end

  
  def initialize(options)
    @id = options['id']
    @user_id = options['user_id']
    @question_id = options['question_id']
  end
  
  def self.followers_for_question_id(question_id)
    qf_data = QuestionsDatabase.instance.execute(<<-SQL,question_id)
      SELECT
        users.id, fname, lname
      FROM
        questions_follows
      JOIN users ON questions_follows.user_id = users.id
      WHERE questions_follows.question_id = ?
    SQL
    qf_data.map { |qf| User.new(qf) }
  end
  
  def self.followed_questions_for_user_id(user_id)
    qf_data = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        questions.id, title, body, author_id
      FROM
        questions_follows
      JOIN questions ON questions_follows.question_id = questions.id
      WHERE questions_follows.user_id = ?
    SQL
    qf_data.map { |qf| Question.new(qf) }
  end
  
  def self.most_followed_questions(n)
    qf_data = QuestionsDatabase.instance.execute(<<-SQL, n)    
    SELECT
      questions.id, title, body, author_id
    FROM
      questions_follows
    JOIN questions ON questions_follows.question_id = questions.id
    JOIN users ON questions_follows.user_id = users.id

    GROUP BY
      questions_follows.question_id
    ORDER BY 
      count(questions_follows.user_id) DESC
    LIMIT ?
    SQL
    
    qf_data.map { |qf| Question.new(qf) }
  end
  
  def create
    raise "#{self} already exists" if @id
    QuestionsDatabase.instance.execute(<<-SQL, @user_id, @question_id)
      INSERT INTO 
        questions_follows (user_id, question_id)
      VALUES
        (?,?)
    SQL
    @id = QuestionsDatabase.instance.last_insert_row_id
  end
end














class QuestionLike
  def self.all 
    q_data = QuestionsDatabase.instance.execute("SELECT * FROM question_likes")
    q_data.map {|q_datum| QuestionLike.new(q_datum)}
  end

  
  def initialize(options)
    @id = options['id']
    @user_id = options['user_id']
    @question_id = options['question_id']
  end
  
  def self.likers_for_question_id(question_id)
    qf_data = QuestionsDatabase.instance.execute(<<-SQL,question_id)
      SELECT
        users.id, fname, lname
      FROM
        question_likes
      JOIN users ON question_likes.user_id = users.id
      WHERE question_likes.question_id = ?
    SQL
    qf_data.map { |qf| User.new(qf) }
  end
  
  def self.num_likes_for_question_id(question_id)
    ql_data = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        count(user_id)
      FROM
        question_likes
      WHERE question_id = ? 
      GROUP BY
        question_id
      -- ORDER BY
      --   count(user_id) DESC
    SQL
    ql_data.values.first
  end
  
  def self.most_liked_questions(n)
    ql_data = QuestionsDatabase.instance.execute(<<-SQL, n)
      SELECT
        questions.id, title, body, author_id
      FROM
        question_likes 
      JOIN questions ON questions.id = question_likes.question_id
      GROUP BY
        question_id
      ORDER BY
        count(user_id) DESC
      LIMIT ?
    SQL
    ql_data.map {|q| Question.new(q)}
  end
  
  def self.liked_questions_for_user_id(user_id)
    qf_data = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        questions.id, title, body, author_id
      FROM
        question_likes
      JOIN questions ON question_likes.question_id = questions.id
      WHERE question_likes.user_id = ?
    SQL
    qf_data.map { |qf| Question.new(qf) }
  end
  
  # def self.most_followed_questions(n)
  #   qf_data = QuestionsDatabase.instance.execute(<<-SQL, n)    
  #   SELECT
  #     questions.id, title, body, author_id
  #   FROM
  #     questions_follows
  #   JOIN questions ON questions_follows.question_id = questions.id
  #   JOIN users ON questions_follows.user_id = users.id
  # 
  #   GROUP BY
  #     questions_follows.question_id
  #   ORDER BY 
  #     count(questions_follows.user_id) DESC
  #   LIMIT ?
  #   SQL
  # 
  #   qf_data.map { |qf| Question.new(qf) }
  # end
  
  def create
    raise "#{self} already exists" if @id
    QuestionsDatabase.instance.execute(<<-SQL, @user_id, @question_id)
      INSERT INTO 
        question_likes (user_id, question_id)
      VALUES
        (?,?)
    SQL
    @id = QuestionsDatabase.instance.last_insert_row_id
  end
end