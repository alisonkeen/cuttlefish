class Email < ActiveRecord::Base
  belongs_to :from_address, :class_name => "EmailAddress"
  has_and_belongs_to_many :to_addresses, :class_name => "EmailAddress", :join_table => "to_addresses_emails"
  after_save :save_data_to_filesystem

  # TODO Add validations

  attr_writer :data

  def from
    # TODO: Remove the "if" once we've added validations
    from_address.address if from_address
  end

  def from=(a)
    self.from_address = EmailAddress.find_or_create_by(address: a)
  end

  def to
    to_addresses.map{|t| t.address}
  end

  def to=(a)
    a = [a] unless a.respond_to?(:map)
    self.to_addresses = a.map{|t| EmailAddress.find_or_create_by(address: t)}
  end

  def to_as_string
    to.join(", ")
  end

  def data
    @data ||= File.read(data_filesystem_path) if is_data_on_filesystem?
  end

  def save_data_to_filesystem
    # Save the data part of the email to the filesystem
    FileUtils::mkdir_p(Email.data_filesystem_directory)
    File.open(data_filesystem_path, "w") do |f|
      f.write(data)
    end
  end

  def is_data_on_filesystem?
    File.exists?(data_filesystem_path)
  end

  def self.data_filesystem_directory
    File.join("db", "emails", Rails.env)
  end

  def data_filesystem_path
    File.join(Email.data_filesystem_directory, "#{id}.txt")
  end

  # Send this mail to another smtp server
  def forward(server, port)
    Net::SMTP.start(server, port) do |smtp|
      smtp.send_message(data, from, to)
    end    
  end
end
