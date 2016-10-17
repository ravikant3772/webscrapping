require 'nokogiri'
require 'open-uri'
require 'sqlite3'

class WebScrapping

	def initialize

		@page = Nokogiri::HTML(open("http://www.recipe.com/"))
		
		@db = SQLite3::Database.new 'webscrap.db'
		 createTable
		@arr_cat=[]
		@arr_res=[]
	end
	#Fetch categories from website
	def getCat      
		puts ''
		puts 'Fetching categories . . '
		@page.css('ul.dropdown li a').each do |cat|
			arr=[]
			arr.push cat.text
			arr.push cat['href']
			@arr_cat.push arr
			print '. '
		end
		i=0
		@arr_cat.each do |pair|
			@db.execute 'insert into category values (?, ? ,?)', i, pair[0], pair[1]
  			i +=1
  		end
	end

	#get Reciepe names from site
	def getRec 
		puts ''
		puts'Fetching recipe names. . '
		@arr_cat.each do |cat|
			link = cat[1]
			catg = cat[0]
			storeRec(link,catg)
			print '. '	
		end
	end

	#store recipe in datbase
	def storeRec(link,catg) 
		res_links = Nokogiri::HTML(open(link))
		i=0
		res_links.css('div.topSection h3 a').each do |res|
			arr=[]
			arr.push res.text 
			arr.push res['href']	
		    @arr_res.push arr
			@db.execute 'insert into recipe values (?, ? ,?, ?,?,?)', i, arr[0], arr[1],catg,'',''
			i += 1

		end

	end

	#Fetching Ingredients and steps
	def getIngrSteps  
		puts ''
		puts 'Fetching Ingridients and Stepdirection . . '
		@arr_res.each do |res|
			link = res[1]
			name1 = res[0]
			print '. '
			#Fetch ingridients for better home and gardens
			if link[11] === 'b'    
				storeIngrSteps(link,name1)

			elsif link[11]==='f' || link[11]==='m' || link[11]==='d' #Fetch ingridients for Publiction family midwest diabetic
				storeIngrSteps2(link,name1)
			
			end
		end
	end

	def storeIngrSteps(link,name1)  #Store ingridients for 
		res_links = Nokogiri::HTML(open(link))
		
		
		# Fetching Ingredients
		ing = "" 
		i=0
		res_links.css('span.recipe__ingredientAmt').each do |amt|
			ing = ing + amt.text+' '+res_links.css('span.recipe__ingredientText')[i].text+', '
			i += 1
		end

		# Fetching Steps for recipe
		i=1
		step=''
		res_links.css('li.recipe__direction').each do |amt|
			
			step = step +i.to_s+'. '+ amt.text + ',  '
			i += 1

		end
		#storing inn database
		@db.execute 'update recipe set ingridients = ? , steps = ? where name = ? ',ing,step,name1


	end

	def storeIngrSteps2(link,name1) #Store ingridients for Publiction family midwest diabetic
		res_links = Nokogiri::HTML(open(link))
		ing = "" 
		
		# Fetching Ingredients
		i=0
		res_links.css('span.ingredientmeasure').each do |amt|
			ing = ing + amt.text+' '+res_links.css('span.name')[i].text+', '
			i += 1
			if res_links.css('span.name').length == i
					break
			end
		end

		# Fetching Steps for recipe
		i=1
		step=''
		res_links.css('span.direction-item-content').each do |amt|
			
			step = step +i.to_s+'. '+ amt.text + ',  '
			i += 1

		end
		#storing inn database
		@db.execute 'update recipe set ingridients = ? , steps = ? where name = ? ',ing,step,name1


	end
	#Store ingridients for recipe.com
	# def storeIngrSteps3(link,name1) 
	# 		ing = "" 
	# 		step =''
			
	# 		begin
	# 		file = open(link)
	# 		res_links = Nokogiri::HTML(file) do
				
	# 			res_links.css('ul.howtoingredients li').each do |amt|
	# 				ing = ing + amt.text+', '
	# 			end

	# 			i=1
	# 			res_links.css('div.stepbystepInstruction').each do |amt|
	# 				step = step +i.to_s+'. '+ (amt.text).strip 
	# 				i += 1
	# 			end

	# 		end
	# 		rescue OpenURI::HTTPError => e
	# 		  if e.message == '404 Not Found'
	# 		    ing = '404 not found'
	# 		    step = '404 not found'
	# 		  else
	# 		    raise e
	# 		  end
	# 		end
	# 		@db.execute 'update recipe set ingridients = ? , steps = ? where name = ? ',ing,step,name1
	# end
	
	

	def createTable
		
		@db.execute "DROP TABLE IF EXISTS category"
		result = @db.execute <<-SQL
		  CREATE TABLE category (
		    id INT,
		    name VARCHAR(30),
		    link VARCHAR(100)
		  );
		SQL
		

		@db.execute "DROP TABLE IF EXISTS recipe"
		result = @db.execute <<-SQL
		  CREATE TABLE recipe (
		    id INT,
		    name VARCHAR(30),
		    link VARCHAR(100),
		    cat VARCHAR(50),
			ingridients  TEXT,		    
			steps TEXT
		  );
		SQL

	end
end
w = WebScrapping.new
w.getCat
w.getRec
w.getIngrSteps
