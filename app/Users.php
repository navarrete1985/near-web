<?php

namespace App;

//use Illuminate\Database\Eloquent\Model;
use Jenssegers\Mongodb\Eloquent\Model as Eloquent;

class Users extends Eloquent
{
    protected $connection = 'mongodb_conn';
    protected $collection = 'users';

    protected $fillable = [
        'connect', 'favorites', 'name', 'email', 'lastName', 'password', 'gender', 'active', 'photo_url', 'rol', 'address', 'phone_number', 'rol'
    ];
}
