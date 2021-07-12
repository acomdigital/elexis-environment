#!/bin/sh
echo "$(date): Elexis-Environment specific setup"
ln -sf /var/www/html /var/www/html/cloud
echo "$(date): Install custom app ..."
rsync -r /var/www/tmp/apps/acom_custom_js_css/ /var/www/html/apps/acom_custom_js_css/
echo "$(date): Update styles in docs ..."
cp /var/www/tmp/core/doc/user/_static/custom.css /var/www/html/core/doc/user/_static/custom.css
cp /var/www/tmp/images/logo.png /var/www/html/core/doc/user/_static/logo-white.png
cp /var/www/tmp/core/doc/user/_static/custom.css /var/www/html/core/doc/admin/_static/custom.css
cp /var/www/tmp/images/logo.png /var/www/html/core/doc/admin/_static/logo-white.png
echo "$(date): Update core template ..."
rsync -r /var/www/tmp/core/templates/ /var/www/html/core/templates/
echo "$(date): Update some apps ..."
rsync -r /var/www/tmp/apps/files/ /var/www/html/apps/files/
rsync -r /var/www/tmp/apps/viewer/ /var/www/html/apps/viewer/
echo "$(date): Update favicon ..."
php /var/www/html/occ theming:config favicon /var/www/tmp/images/favicon.ico
echo "$(date): Update logo ..."
php /var/www/html/occ theming:config logoheader /var/www/tmp/images/logo.png
php /var/www/html/occ theming:config logo /var/www/tmp/images/logo.png
echo "$(date): Assert user_saml app is installed ..."
php /var/www/html/occ app:install user_saml
echo "$(date): Assert acom_custom_js_css app is enabled ..."
php /var/www/html/occ app:enable acom_custom_js_css
echo "$(date): Check big int conversion ..."
php /var/www/html/occ db:convert-filecache-bigint
echo "$(date): Check indices ..."
php /var/www/html/occ db:add-missing-indices
echo "$(date): Add missing optional columns ..."
php /var/www/html/occ db:add-missing-columns

# TODO external storage support aktivieren?

# we have to return 0, as calling script is set -e
# which will exit if user_saml is already installed (return code)
return 0
