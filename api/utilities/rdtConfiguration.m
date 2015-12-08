function configuration = rdtConfiguration(varargin)
%% Initialize a struct with RemoteDataToolbox configuration.
%
% This function initializes a config struct that you can pass to other
% toolbox functions.  Config fields begin with default values declared in
% this function.  These may be amended with values read from a named
% JSON-file or passed in as a struct or name-value pairs.
%
% configuration = rdtConfiguration(projectName) uses the given name to
% locate a JSON file that contains configuraiton values.  For example, if
% projectName is "foo", searches for the file "rdt-config-foo.json".  First
% searches pwd(), then the parent folders of pwd(), then the Matlab path.
%
% configuration = rdtConfiguration(jsonFile) loads configuration values
% from the given jsonFile.
%
% configuration = rdtConfiguration(initialConfig) amends the default
% configuration using fields from the given initialConfig struct.
%
% configuration = rdtConfiguration('field1', value1, 'field2', value2, ...)
% amends the default configuration using the named field-value pairs.
%
% This function may pop up a dialog prompting you to enter a username and
% password to include in the configuration.  The dialog will only pop up if
% two conditions are met:
%   1. configuration.username is not empty and not "guest", and
%   2. configuration.password is empty
%
% Returns a struct with toolbox configuration with at least the default
% fields and values.
%
% configuration = rdtConfiguration(varargin)
%
% Copyright (c) 2015 RemoteDataToolbox Team

%% What did the user pass in?
configArgs = {};
if 0 == nargin
    fprintf('Using default config.\n');
elseif 1 == nargin
    arg = varargin{1};
    if ischar(arg)
        % struct from project name or json file path
        configArgs = {configFromJson(arg)};
    elseif isstruct(arg)
        % explicit struct
        configArgs = {arg};
    else
        fprintf('Using default config.\n');
    end
else
    % explicit name-value pairs
    configArgs = varargin;
end

%% Declare expected args and default values.
parser = rdtInputParser();
parser.StructExpand = true;
parser.addParameter('serverUrl', '');
parser.addParameter('repositoryUrl', '');
parser.addParameter('repositoryName', '');
parser.addParameter('username', 'guest');
parser.addParameter('password', '');
parser.addParameter('requestMediaType', 'application/json');
parser.addParameter('acceptMediaType', 'application/json');
parser.addParameter('cacheFolder', '');

%% Parse given config through the declared config scheme.
parser.parse(configArgs{:});
configuration = rdtMergeStructs(parser.Results, parser.Unmatched, true);

%% Prompt for credentials if needed.
if isempty(configuration.password) ...
        && ~isempty(configuration.username) ...
        && ~strcmp('guest', configuration.username)
    
    % got a real username and no password -- ask for the password
    configuration = rdtCredentialsDialog(configuration);
end

%% Load config from a JSON file.
function configArgs = configFromJson(arg)

configArgs = struct();

[~, argBase, argExt] = fileparts(arg);
if strcmp('.json', argExt) && 2 == exist(arg, 'file')
    % got explicit path to a JSON file
    fprintf('Using config from explicit file: %s\n', arg);
    configArgs = rdtFromJson(arg);
    return;
end

% got a project name foo, search for rdt-config-foo.json
jsonFileName = ['rdt-config-' argBase '.json'];

% search the current folder and its parents
projectConfig = rdtSearchParentFolders(jsonFileName, pwd());
if 2 == exist(projectConfig, 'file')
    fprintf('Using config for "%s" project: %s\n', arg, projectConfig);
    configArgs = rdtFromJson(projectConfig);
    return;
end

% search the Matlab path
pathConfig = which(jsonFileName);
if ~isempty(pathConfig)
    fprintf('Using config from Matlab path: %s\n', pathConfig);
    configArgs = rdtFromJson(pathConfig);
    return;
end

% unable to locate JSON
fprintf('Could not find config named "%s" or "%s"\n', arg, jsonFileName);