import { Component, VERSION } from '@angular/core';

@Component({
    selector: 'app-main',
    template: '<h1>Esto es la versión de Angular {{ version }}</h1>'
})

export class AppComponent {
    version = VERSION.full;
}
