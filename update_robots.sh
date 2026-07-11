#!/bin/sh

cat <<EOF > ./robots.txt
#   HeLlO, FrIeNd ...
#
#      ,.::::://        \\\\:::::.,       
#                                       
#                                       
#      \.\.\....        ..../././       
#      :   o    :      :   o    :       
#       :\`:\`:\`\`\`        \`\`\`:.:\`:        
#         .  .           :  .           
#                           .           
#                 _  _                  
#                                       
#                                       
#             \`..::..::..'              
#               ' v  v '                
#               \`:....:'                
#                                       
#   WHaT do YoU ThiNk you'RE DoInG ?

# Don't allow indexing of /static and /html directories:
User-agent: *
Disallow: /static
Disallow: /html

# Don't allow indexing of about.html:
User-agent: *
Disallow: /about.html

# Don't allow indexing of plaintext/md files
# and .meta metadata files:
User-agent: *
Disallow: /*.md
Disallow: /*.djot
Disallow: /*.meta

# Don't allow indexing of .git directories
# (which should be blocked by httpd regardless)
User-agent: *
Disallow: /*.git
Disallow: /*.gitignore

# *wink*
User-agent: *
Disallow: /a_security_analysis_of_tinyjambu.pdf

# Don't allow Turnitin to index my shit:
User-Agent: TurnitinBot
Disallow: /

# Don't allow intellectual property (IP) bots:
User-Agent: NPBot
Disallow: /
User-Agent: SlySearch
Disallow: /

# Don't allow AI to train on my shit:
# https://github.com/ai-robots-txt/ai.robots.txt
EOF

ftp -o- "https://raw.githubusercontent.com/ai-robots-txt/ai.robots.txt/refs/heads/main/robots.txt" >> ./robots.txt
