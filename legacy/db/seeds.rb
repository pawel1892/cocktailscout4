role_member = Role.create(name: 'member')
role_forum_moderator = Role.create(name: 'forum_moderator')
role_image_moderator = Role.create(name: 'image_moderator')
rote_recipe_moderator = Role.create(name: 'recipe_moderator')
role_admin = Role.create(name: 'admin')

# admin_user = User.create(email: 'webmaster@cocktailscout.de', password: '123456', login: 'admin')
# admin_user.add_role 'admin'
#
# user = User.create(email: 'member@cocktailscout.de', password: '123456', login: 'member')
#
# ingredient_gin = Ingredient.create(name: 'Gin')
# ingredient_grenadine = Ingredient.create(name: 'Grenadine')
# ingredient_limettensaft = Ingredient.create(name: 'Limettensaft')
# ingredient_mandelsirup = Ingredient.create(name: 'Mandelsirup')
# ingredient_orangensaft = Ingredient.create(name: 'Orangensaft')
# ingredient_rohrzuckersirup = Ingredient.create(name: 'Rohrzuckersirup')
# ingredient_rum_braun = Ingredient.create(name: 'Rum braun')
# ingredient_tequila = Ingredient.create(name: 'Tequila')
# ingredient_triple_sec_curacao = Ingredient.create(name: 'Triple Sec Curacao')
# ingredient_wodka = Ingredient.create(name: 'Wodka')
# ingredient_zitronensaft = Ingredient.create(name: 'Zitronensaft')
#
# recipe_hs = Recipe.create(name: 'Hemingway Sour', description: 'Alle Zutaten mit Crushed Ice bootyshaken.', user: user)
# recipe_hs.recipe_ingredients.create(ingredient_id: ingredient_gin.id, description: '4 cl Gin')
# recipe_hs.recipe_ingredients.create(ingredient_id: ingredient_grenadine.id, description: '2 cl Grenadine')
# recipe_hs.recipe_ingredients.create(ingredient_id: ingredient_zitronensaft.id, description: '3 cl Zitronensaft')
# recipe_hs.tag_list = ['sauer', 'Migrant']
#
# recipe_ts = Recipe.create(name: 'Tequila Sunrise', description: 'Alle Zutaten mit Crushed Ice shaken.', user: user)
# recipe_ts.recipe_ingredients.create(ingredient_id: ingredient_tequila.id, description: '6 cl Tequila')
# recipe_ts.recipe_ingredients.create(ingredient_id: ingredient_grenadine.id, description: '1 cl Grenadine')
# recipe_ts.recipe_ingredients.create(ingredient_id: ingredient_zitronensaft.id, description: '1 cl Zitronensaft')
# recipe_ts.recipe_ingredients.create(ingredient_id: ingredient_orangensaft.id, description: '12 cl Orangensaft')
# recipe_ts.tag_list = ['rotfront', 'Getränk']
#
# recipe_mt = Recipe.create(name: 'Mai Tai', description: 'Alle Zutaten gut shaken und in ein Cocktailglas mit Eiswürfeln füllen.
# Kann noch etwas mit Crushed Ice aufgefüllt werden. Auch möglich ist es einen Schuss Grenadine (1-2 cl) hineinzugeben.
#
# Schmeckt sehr mild im Vergleich zum Alkoholgehalt. Der Mai Tai gehört zu den bekanntesten Cocktails.
#
# Trader Vic\'s ORIGINAL FORMULA:
# 2 ounces 17-year-old J. Wray Nephew Jamaican Rum
# 1/2 ounce French Garnier Orgeat
# 1/2 ounce Holland DeKuyper Orange Curacao
# 1/4 ounce Rock Candy Syrup
# Juice from 1 fresh Lime
# Shake and garnish with half of the lime shell inside the drink and float a sprig of fresh mint at the edge of the glass.', user: user)
# recipe_mt.recipe_ingredients.create(ingredient_id: ingredient_rum_braun.id, description: '4 cl Rum (braun)')
# recipe_mt.recipe_ingredients.create(ingredient_id: ingredient_triple_sec_curacao.id, description: '2 cl Triple Sec Curaçao')
# recipe_mt.recipe_ingredients.create(ingredient_id: ingredient_rohrzuckersirup.id, description: '1 cl Rohrzuckersirup')
# recipe_mt.recipe_ingredients.create(ingredient_id: ingredient_mandelsirup.id, description: '2 cl Mandelsirup')
# recipe_mt.recipe_ingredients.create(ingredient_id: ingredient_limettensaft.id, description: '2 cl Limettensaft')
# recipe_mt.tag_list = ['Wix', 'Getränk']
#
# user.recipes << [recipe_hs, recipe_mt, recipe_ts]
# user.save
#
# forum_topic_1 = ForumTopic.create(id: 1, name: 'Allgemeine Diskussion', description: 'Alles rund ums Cocktailmixen', sorting: 1)
# forum_topic_2 = ForumTopic.create(id: 2, name: 'Cocktailzutaten', description: 'Welche Zutaten wo kaufen und wie verwenden?', sorting: 100)
# forum_topic_3 = ForumTopic.create(id: 3, name: 'Bars & Nightlife', description: 'Erfahrungsberichte und Bars in Eurer Region', sorting: 200)
# forum_topic_4 = ForumTopic.create(id: 4, name: 'Offtopic', description: 'Diskussion über Alles, was sonst keinen Platz findet', sorting: 300)
# forum_topic_5 = ForumTopic.create(id: 5, name: 'Feedback', description: 'Lob, Kritik, Verbesserungsvorschläge und Hilfe', sorting: 400)
# forum_topic_6 = ForumTopic.create(id: 6, name: 'Fotodiskussionen', description: 'Wie können die Fotos verbessert werden', sorting: 500)
# forum_topic_7 = ForumTopic.create(id: 7, name: 'Rezeptvorschläge', description: 'Diskussionen zu Rezeptvorschlägen', sorting: 600)
#
# forum_thread_1 = ForumThread.new(id: 1, forum_topic_id: forum_topic_1.id, title: 'Erster!', user_id: user.id)
# forum_thread_1.forum_posts.build(forum_thread_id: forum_thread_1.id, user_id: user.id, content: 'Erster!!1111einseinself')
# forum_thread_1.forum_posts.build(forum_thread_id: forum_thread_1.id, user_id: admin_user.id, content: 'Das sagste zu deine Frau auch immer, oder?')
# forum_thread_1.save
#
# forum_thread_2 = ForumThread.new(id: 2, forum_topic_id: forum_topic_1.id, title: 'Zweiter!', user_id: user.id)
# forum_thread_2.forum_posts.build(forum_thread_id: forum_thread_2.id, user_id: user.id, content: 'Zweiter!!!1111einseinself')
# forum_thread_2.save
#
# forum_thread_3 = ForumThread.new(id: 3, forum_topic_id: forum_topic_2.id, title: 'Bacardi oder Cola?', user_id: user.id)
# forum_thread_3.forum_posts.build(forum_thread_id: forum_thread_3.id, user_id: user.id, content: 'Was ist besser zum putzen?')
# forum_thread_3.forum_posts.build(forum_thread_id: forum_thread_3.id, user_id: admin_user.id, content: 'Bacardi für Fenster. Cola für den Küchenboden. ;)')
# forum_thread_3.save
#
# UserRank.all.each{|u| u.recalculate_points!}
