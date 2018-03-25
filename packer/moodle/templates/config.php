<?php  // Moodle configuration file

// Not the most secure way, also, need to stop the instance if the username or password is changed. A temporary measure until Vault is implemented.
$jsondbcredentials = @file_get_contents("http://169.254.169.254/latest/user-data");
$dbcredentials = json_decode($jsondbcredentials);

unset($CFG);
global $CFG;
$CFG = new stdClass();

$CFG->dbtype    = 'pgsql';
$CFG->dblibrary = 'native';
$CFG->dbhost    = strtok($dbcredentials->POSTGRES_ENDPOINT, ':');
$CFG->dbname    = $dbcredentials->POSTGRES_DB_NAME;
$CFG->dbuser    = $dbcredentials->POSTGRES_USER;
$CFG->dbpass    = $dbcredentials->POSTGRES_PASS;
$CFG->prefix    = 'mdl_';
$CFG->dboptions = array (
    'dbpersist' => 0,
    'dbport' => 5432,
    'dbsocket' => '',
);

$CFG->wwwroot   = 'http://mfabriczy.com';
$CFG->dataroot  = '/usr/share/nginx/moodledata';
$CFG->admin     = 'admin';

$CFG->directorypermissions = 0777;

require_once(__DIR__ . '/lib/setup.php');

// There is no php closing tag in this file,
// it is intentional because it prevents trailing whitespace problems!