include(m4/head.m4)dnl
define(TITLE, `Title')dnl
define(CREATED, esyscmd(`date +%F'))dnl
define(MODIFIED, esyscmd(`date +%F'))dnl
define(MDFILE, `./in/post.md')dnl
dnl
dnl compile .md to html, and append two tab chars to the beginning of each line.dnl
dnl define(CONTENT, `esyscmd(`lowdown -T html -D smarty' MDFILE `| sed -E "s/^/		/g"')')dnl
define(CONTENT, `esyscmd(`lowdown -T html -D smarty' MDFILE)')dnl
<html>
	_HEAD(TITLE)
	<body>
	_NAV
	<main>
		CONTENT
		<ul class="info">
			<li>CREATED</li>
			<li><a href="MDFILE">MDFILE</a></li>
			<li>LAST `MODIFIED': MODIFIED</li>
		</ul>
	</main>
	</body>
</html>
