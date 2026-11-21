Product.delete_all

[
  { title: "Programming Ruby",    description: "The pragmatic programmer's guide.", price: 49.95 },
  { title: "Agile Web Development", description: "With Rails.",                     price: 54.95 },
  { title: "Rails Recipes",       description: "Short, direct solutions.",          price: 44.95 }
].each { |attrs| Product.create!(attrs) }
