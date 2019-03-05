MY=(
    [ROLE]=app
    [RUN_AS]=www

    [APP_NAME]="${APP_NAME:-TurnKey WordPress}"
    [APP_USER]="${APP_USER:-admin}"
    [APP_MAIL]="${APP_MAIL:-admin@example.com}"
    [APP_PASS]="${APP_PASS:-}"
    [APP_SITE]="${APP_SITE:-}" # TODO
    [APP_MODS]="${APP_MODS:-}" # TODO

    [DB_HOST]="${DB_HOST:-127.0.0.1}"
    [DB_USER]="${DB_USER:-wordpress}"
    [DB_NAME]="${DB_NAME:-wordpress}"
    [DB_PASS]="${DB_PASS:-$(secret consume DB_PASS)}"
    [DB_PREFIX]="${DB_PREFIX:-wp_}"

    [CONFIG_EXTRA]="${CONFIG_EXTRA:-}" # TODO
)

passthrough_unless "php-fpm" "$@"

add vhosts wordpress
web_extract_src wordpress

random_if_empty APP_PASS
cd "${OUR[WEBDIR]}"

carefully wp config create \
    --dbname="${MY[DB_NAME]}" \
    --dbuser="${MY[DB_USER]}" \
    --dbpass="${MY[DB_PASS]}" \
    --dbhost="${MY[DB_HOST]}" \
    --dbprefix="${MY[DB_PREFIX]}" \
    --skip-check

poll carefully wp core install \
    --title="${MY[APP_NAME]}" \
    --url="${MY[APP_SITE]}" \
    --admin_user="${MY[APP_USER]}" \
    --admin_password="${MY[APP_PASS]}" \
    --admin_email="${MY[APP_MAIL]}" \
|| fatal "failed to install WordPress"

cat > content.txt <<<'Getting started...
<ul>
    <li><a href="/wp-login.php">Login</a> as <b>admin</b> and get blogging!</li>
    <li>Refer to the <a href="http://www.turnkeylinux.org/wordpress">TurnKey WordPress release notes</a></li>
    <li>Refer to the <a href="http://codex.wordpress.org/Getting_Started_with_WordPress">Wordpress Getting Started Codex</a></li>
    <li>Check out some of the numerous WordPress plugins:
        <ul>
            <li><a href="http://yoast.com/wordpress/seo/">Wordpress-SEO</a>: Optimizes your WordPress blog for search engines and XML sitemaps.</li>
            <li><a href="http://wordpress.org/extend/plugins/nextgen-gallery/">NextGEN Gallery</a>: Easy to use image gallery with a Flash slideshow option.</li>
            <li><a href="http://wordpress.org/extend/plugins/jetpack/">JetPack for WordPress</a>: Jetpack adds powerful features previously only available to WordPress.com users including customization, traffic, mobile, content, and performance tools.</li>
            <li><a href="http://wordpress.org/extend/plugins/wp-super-cache/">WP Super Cache</a>: Accelerates your blog by serving 99% of your visitors via static HTML files.</li>
            <li><a href="http://wordpress.org/extend/plugins/ultimate-social-media-icons/">Ultimate Social Media Icons</a>: Promote your content by adding links to social sharing and bookmarking sites.</li>
            <li><a href="http://wordpress.org/extend/plugins/simple-tags/">Simple Tags</a>: automatically adds tags and related posts to your content.</li>
            <li><a href="http://wordpress.org/extend/plugins/backupwordpress/">BackupWordPress</a>: easily backup your core WordPress tables.</li>
            <li><a href="http://yoast.com/wordpress/google-analytics/">Google Analytics for WordPress</a>: track visitors, AdSense clicks, outgoing links, and search queries.</li>
            <li><a href="http://wordpress.org/extend/plugins/wp-polls/">WP-Polls</a>: Adds an easily customizable AJAX poll system to your blog.</li>
            <li><a href="http://wordpress.org/extend/plugins/wp-updates-notifier/">WP-PageNavi</a>: Adds more advanced paging navigation.</li>
            <li><a href="http://wordpress.org/extend/plugins/wp-pagenavi/">Ozh admin dropdown menu</a>: Creates a drop down menu with all admin links.</li>
            <li><a href="http://wordpress.org/extend/plugins/ozh-admin-drop-down-menu/">Contact From 7</a>: Customizable contact forms supporting AJAX, CAPTCHA and Akismet integration.</li>
            <li><a href="http://wordpress.org/extend/plugins/contact-form-7/">WP-Update-Notifier</a>: Sends email to notify you if there are any updates for your WordPress site. Can notify about core, plugin and theme updates.</li>
            <li><a href="http://wordpress.org/extend/plugins/seriously-simple-podcasting/">Seriously Simple Podcasting</a>: Simple Podcasting from your WordPress site.</li>
        </ul>
    </li>
</ul>'

carefully wp post create \
    content.txt \
    --post-title="Welcome to WordPress!" \
    --post-status="publish" \
    --post-excerpt="..."

rm content.txt

carefully wp config set --type=constant --raw WP_SITEURL "'http://' . \$_SERVER['HTTP_HOST']"
carefully wp config set --type=constant --raw WP_HOME "'http://' . \$_SERVER['HTTP_HOST']"

reload_vhosts
run "$@"
