include(m4/head.m4)dnl
define(TITLE, `Article Title')dnl
define(CREATED, esyscmd(`date +%F'))dnl
define(MODIFIED, esyscmd(`date +%F'))dnl
define(MDFILE, `./in/post.md')dnl
define(CONTENT, `esyscmd(`lowdown -T html -D smarty' MDFILE)')dnl
<!DOCTYPE html>
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
