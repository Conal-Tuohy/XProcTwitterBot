# XProcTwitterBot
A Twitter bot for XML hackers

XProcTwitterBot is a TwitterBot written in the XProc language.

To run this bot, you will need to install the [XMLCalabash](http://xmlcalabash.com/) XProc interpreter, because the Bot makes use of one or two Calabash extensions that aren't available with other XProc engines. I hope to convert it to a fully standard XProc eventually.

You will also need to go to Twitter and create a user account for your TwitterBot, and also register an App, and grant your App the right to post on behalf of your user. This will yield four credentials (`consumer-key`, `consumer-secret`, `access-token`, and `access-token-secret`) which you must pass to the `twitter-bot.xpl` pipeline when you run it. e.g.

`java -jar xmlcalabash.jar` `--with-param consumer-key="XXXXXXX"` `--with-param consumer-secret="XXXXXXX"` `--with-param access-token="XXXXXXXX"` `--with-param access-token-secret="XXXXXXX"` `twitter-bot.xpl`

The bot makes a series of queries to the National Library of New Zealand's [Papers Past](http://paperspast.natlib.govt.nz/) website; firstly to search for illustrations published exactly 100 years ago, then to retrieve the first matching page, then finally to retrieve the image itself from that page. After that the bot uploads the image to Twitter, and then creates a tweet containing the headline, the title of the newspaper, a link to the page on Papers Past, and the image itself.
