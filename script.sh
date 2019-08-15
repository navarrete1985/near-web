#!/usr/bin/env bash

#
# Author: Robert Brisita <[first-initial][last name] at gmail dot com>
#
# An Angular installation script for a Laravel project.
# This should be run on a new Laravel project install.
#
# Tested on Mac OS X 10.13.6
#
# Version 2019-04-18
#

set -o nounset # abort on unbound variable

if [ -d 'node_modules' ]; then
    read -n 1 -p $'The \'node_modules\' directory is present. Are you sure you want to proceed? (y/N): ' proceed \
    && [[ "$proceed" == [yY] ]] || { echo; exit 1; }
fi

echo # noop
ANGULAR_VERSION=${1:-''}
if [ -z "${ANGULAR_VERSION}" ]; then
    read -p 'Which Angular version would you like? ' ANGULAR_VERSION
fi

[[ "${ANGULAR_VERSION}" =~ ^[\^~]*[4-7][\.0-9]*[\.0-9]*$ || "${ANGULAR_VERSION}" == 'latest' ]] \
|| { echo "v${ANGULAR_VERSION} in untested and not valid."; exit 2; }

ANGULAR_MAX_VERSION=$(echo "${ANGULAR_VERSION}" | cut -d '.' -f 1)

LARAVEL_VERSION=$(php artisan --version | awk '{ print $NF }')
LARAVEL_MAX_VERSION=$(echo "${LARAVEL_VERSION}" | cut -d '.' -f 1)
LARAVEL_MIN_VERSION=$(echo "${LARAVEL_VERSION}" | cut -d '.' -f 2)

if [[ "${LARAVEL_MAX_VERSION}" -ne 5 || "${LARAVEL_MIN_VERSION}" -lt 4 ||  "${LARAVEL_MIN_VERSION}" -gt 8 ]]; then
    echo -e "Laravel v${LARAVEL_VERSION} not tested."
    exit 3
fi

echo -e "\\n*****\\n* Remove Preset Frontend.\\n*****\\n"
if [ "${LARAVEL_MIN_VERSION}" -lt 5 ]; then
    # Laravel 5.4-
    npm remove --save-dev axios
    npm remove --save-dev jquery
    npm remove --save-dev vue
    npm remove --save-dev bootstrap-sass
fi

if [ "${LARAVEL_MIN_VERSION}" -ge 5 ]; then
    # Laravel 5.5+
    php artisan preset none
    npm remove --save-dev axios
fi

if [ "${LARAVEL_MIN_VERSION}" -ge 6 ]; then
    # Laravel 5.6+
    npm remove --save-dev bootstrap
    npm remove --save-dev popper.js
fi

if [ "${LARAVEL_MIN_VERSION}" -ge 7 ]; then
    # Laravel 5.7+
    npm remove --save-dev resolve-url-loader
    npm remove --save-dev sass
    npm remove --save-dev sass-loader
    RESOURCES_PATH='resources'
else
    # Laravel 5.7-
    RESOURCES_PATH='resources/assets'
fi

echo -e "\\n*****\\n* Delete Old JS and CSS.\\n*****\\n"
if [ -d "${RESOURCES_PATH}/js" ]; then
    rm -rf ${RESOURCES_PATH}/js
fi

if [ -d "${RESOURCES_PATH}/sass" ]; then
    rm -rf ${RESOURCES_PATH}/sass
fi

if [ -r 'public/css/app.css' ]; then
    rm public/css/app.css
fi

if [ -r 'public/js/app.js' ]; then
    rm public/js/app.js
fi

echo -e "\\n*****\\n* Install TypeScript.\\n*****\\n"
# Pinning to certain versions to resolve dependency issues:
# ts-loader Webpack v4 issues and core-js reflection issue.
npm install --save-dev @types/node typescript ts-loader@~3.5 core-js@^2

echo -e "\\n*****\\n* Install Angular.\\n*****\\n"
if [ "${ANGULAR_MAX_VERSION}" -eq 4 ]; then
    # Satisfy @angular@4.4.7 peer dependencies
    npm install --save-dev rxjs@^5.0.1 zone.js@^0.8.4
elif [ "${ANGULAR_MAX_VERSION}" -eq 5 ]; then
    # Satisfy @angular@5.2.11 peer dependencies
    npm install --save-dev rxjs@^5.5.0 zone.js@^0.8.4
elif [ "${ANGULAR_MAX_VERSION}" -ge 6 ]; then
    # Satisfy @angular@6.1.10 and @angular@7.2.13 peer dependencies
    npm install --save-dev rxjs@^6.0.0 zone.js@~0.8.26
else # [ "${ANGULAR_MAX_VERSION}" == "latest" ]
    npm install --save-dev rxjs core-js zone.js
fi

npm install --save-dev @angular/core@"${ANGULAR_VERSION}" @angular/common@"${ANGULAR_VERSION}" \
@angular/platform-browser@"${ANGULAR_VERSION}" @angular/compiler@"${ANGULAR_VERSION}" \
@angular/platform-browser-dynamic@"${ANGULAR_VERSION}"

echo -e "\\n*****\\n* Install Laravel Frontend Dependencies.\\n*****\\n"
npm install --save-dev laravel-mix cross-env

echo -e "\\n*****\\n* Create TypeScript Path and Files.\\n*****\\n"
TS_PATH="${RESOURCES_PATH}/ts"
mkdir -p ${TS_PATH}/components

echo -e "\\n*****\\n* Create '${TS_PATH}/vendor.ts' file.\\n*****\\n"
cat > "${TS_PATH}/vendor.ts" << VENDOR_TS_EOF
// Angular
import '@angular/core';
import '@angular/common';
import '@angular/platform-browser';
import '@angular/platform-browser-dynamic';

// RxJS
import 'rxjs';
VENDOR_TS_EOF

echo -e "\\n*****\\n* Create '${TS_PATH}/main.ts' file.\\n*****\\n"
cat > "${TS_PATH}/main.ts" << MAIN_TS_EOF
import 'core-js/es7/reflect';
import 'zone.js/dist/zone';

import { enableProdMode } from '@angular/core';
import { platformBrowserDynamic } from '@angular/platform-browser-dynamic';
import { AppModule } from './components/app.module';

if (process.env.ENV === 'production') {
    enableProdMode();
}

platformBrowserDynamic().bootstrapModule(AppModule);
MAIN_TS_EOF

echo -e "\\n*****\\n* Create '${TS_PATH}/components/app.component.ts' file.\\n*****\\n"
cat > "${TS_PATH}/components/app.component.ts" << APP_COMPONENT_TS_EOF
import { Component, VERSION } from '@angular/core';

@Component({
    selector: 'app-main',
    template: '<h1>Angular v{{ version }}</h1>'
})

export class AppComponent {
    version = VERSION.full;
}
APP_COMPONENT_TS_EOF

echo -e "\\n*****\\n* Create '${TS_PATH}/components/app.module.ts' file.\\n*****\\n"
cat > "${TS_PATH}/components/app.module.ts" << APP_MODULE_TS_EOF
import { AppComponent } from './app.component';
import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';

@NgModule({
    imports: [BrowserModule],
    declarations: [AppComponent],
    bootstrap: [AppComponent]
})

export class AppModule {
}
APP_MODULE_TS_EOF

echo -e "\\n*****\\n* Rewrite 'resources/view/welcome.blade.php' file.\\n*****\\n"
cat > "resources/views/welcome.blade.php" << WELCOME_BLADE_EOF
<!doctype html>
<html lang="en">
    <head>
        <meta charset="utf-8">
        <meta http-equiv="X-UA-Compatible" content="IE=edge">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>Laravel and Angular: Automated</title>
    </head>
    <body style="text-align: center;">
        <h1>Laravel v{{ App::VERSION() }}</h1>
        <app-main>Loading...</app-main>
        <h1>Automated</h1>
        <script type="text/javascript" src="{{ mix('js/vendor.js') }}"></script>
        <script type="text/javascript" src="{{ mix('js/app-component.js') }}"></script>
    </body>
</html>
WELCOME_BLADE_EOF

echo -e "\\n*****\\n* Create 'tsconfig.json' file.\\n*****\\n"
cat > "tsconfig.json" << TSCONFIG_JSON_EOF
{
    "compilerOptions": {
        "module": "commonjs",
        "moduleResolution": "node",
        "experimentalDecorators": true,
        "emitDecoratorMetadata": true,
        "noUnusedLocals": true,
        "noImplicitAny": true,
        "noImplicitThis": true,
        "strictNullChecks": true,
        "lib": [
            "dom",
            "es2015"
        ]
    },
    "exclude": [
        "node_modules",
        "vendor"
    ]
}
TSCONFIG_JSON_EOF

echo -e "\\n*****\\n* Create 'webpack-custom.mix.js' file.\\n*****\\n"
if [ "${ANGULAR_MAX_VERSION}" -eq 4 ]; then
    # Fix: WARNING in ./node_modules/@angular/core/@angular/core.es5.js
    CORE_FOLDER='@angular'
elif [ "${ANGULAR_MAX_VERSION}" -eq 5 ]; then
    # Fix: WARNING in ./node_modules/@angular/core/esm5/core.js
    CORE_FOLDER='esm5'
elif [ "${ANGULAR_MAX_VERSION}" -ge 6 ]; then
    # Fix: WARNING in ./node_modules/@angular/core/fesm5/core.js
    CORE_FOLDER='fesm5'
fi

cat > "webpack-custom.mix.js" << WEBPACK_CUSTOM_MIX_JS_EOF
let mix = require('laravel-mix');
let path = require('path');
let webpack = require('webpack');

mix.webpackConfig({
    resolve: {
        extensions: ['.ts']
    },

    module: {
        rules: [
            {
                test: /\.ts$/,
                loader: 'ts-loader'
            }
        ]
    },

    plugins: [
        new webpack.ContextReplacementPlugin(
            /\@angular(\\\|\/)core(\\\|\/)${CORE_FOLDER}/,
            path.join(__dirname, './src')
        )
    ]
});
WEBPACK_CUSTOM_MIX_JS_EOF

echo -e "\\n*****\\n* Rewrite 'webpack.mix.js' file.\\n*****\\n"
cat > "webpack.mix.js" << WEBPACK_MIX_JS_EOF
let mix = require('laravel-mix');
require('./webpack-custom.mix');

mix.js([
    '${RESOURCES_PATH}/ts/vendor.ts'
], 'public/js/vendor.js');

mix.js([
    '${RESOURCES_PATH}/ts/main.ts'
], 'public/js/app-component.js')
WEBPACK_MIX_JS_EOF

echo -e "\\n*****\\n* Building Development and Running Server.\\n*****\\n"
npm run dev && php artisan serve