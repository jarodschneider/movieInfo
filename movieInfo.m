function [out] = movieInfo(title,OMDbKey,topic)
%MOVIEINFO  gets movie info from OMDb API
%   out = movieInfo(title) returns all information about movie by title (see list below)
%
%   out = movieInfo(title,topic) returns a specific piece of information (char)
%
%   List of allowed topics:
%   'Summary' - returns brief summary of data and the movie's poster
%   'Year' - release year YYYY
%   'Released' - specific release date DD M YYYY
%   'Runtime' - runtime in minutes
%   'Genre' - movie's genres
%   'Director' - movie's director
%   'Writer' - movie's writer(s)
%   'Actors' - leading 4 actors
%   'Plot' - brief plot summary
%   'Language' - movie's language
%   'Country' - list of production countries
%   'Awards' - description of awards won
%   'Poster' - displays movie poster
%   'Ratings' - cell array of IMDb, Rotten Tomatoes, and Metacritic scores
%   'Metascore' - movie's Metacritic score
%   'RT' - movie's Rotten Tomatoes score
%   'IMDb' - movie's IMDb score
%   'imdbVotes' - number of IMDb votes
%   'imdbID' - movie's IMDbID (www.imdb.com/title/'imdbID')
%   'DVD' - DVD release date DD M YYYY
%   'BoxOffice' - domestic box office in USD
%   'Production' - studio
%   'Website' - movie's website URL
warning('off','all'); % spaces must be converted, but throws warning, so warnings off

data = webread(sprintf('http://www.omdbapi.com/?apikey=%s&t=%s',OMDbKey,title)); % pull from API, parse JSON

if strcmp(data.Response,'False') % movie not found
    out = sprintf('Sorry, %s was not found. Please try a different title.',title);
else
    data = rmfield(data,'Response'); % useless field, if movie exists will always be true
    
%   although OMDb API supports movies and TV shows, the scope of the
%   problem only includes movies
    data = rmfield(data,'Type');
    switch nargin % third input optional
        case 3
            switch topic
                case 'Poster' % want to show poster, not URL
                    img = imread(data.Poster);
                    imshow(img);
                    return;
                case 'IMDb'
                    topic = 'imdbRating'; % 'IMDb' more intuitive for user
                case 'RT'
                    out = data.Ratings{2}.Value; % RT ratings inside structure array 'Ratings' by default
                    return;
                case 'Summary'
                    out = helper(data); % build summary
                    img = imread(data.Poster);
                    imshow(img); % display poster
                    return;
            end
            out = data.(topic); % no special case
        case 2
            out = data;
        case 1
            out = 'title or API key missing.';
    end
end
end

function out = helper(data)
% API returns without ', and' next two lines fix
commas = strfind(data.Actors,',');
stars = [data.Actors(1:commas(end)), ' and', data.Actors(commas(end) + 1:end)];

bo = data.BoxOffice(2:end); % no '$' for math
commas = strfind(bo,',');
bo(commas) = ''; % no ',' for math
bo = str2num(bo);
if bo >= 100000000
    money = sprintf('It was a box office success, earning %s',data.BoxOffice);
else
    money = sprintf('It was not a huge box office performer, earning only %s',data.BoxOffice);
end

MC = str2num(data.Metascore);
users = str2num(data.imdbRating) * 10;
if MC - users >= 15
    rating = sprintf('better by critics than general audiences, having a Metascore of %s compared to an IMDb rating of %s/10',data.Metascore,data.imdbRating);
elseif users - MC >= 15
    rating = sprintf('worse by critics than general audiences, who gave the film a rating of %s/10 compared to a Metascore of %s',data.imdbRating,data.Metascore);
elseif MC <= 60
    rating = sprintf('just as poorly by critics as it was by general audiences, with a Metascore of %s and IMDb rating of %s/10',data.Metascore,data.imdbRating);
elseif MC >= 80
    rating = sprintf('well by both critics and general audiences, with a Metascore of %s and IMDb rating of %s/10',data.Metascore,data.imdbRating);
else
    rating = sprintf('similarly by both critics and general audiences, with a Metascore of %s and IMDb rating of %s/10',data.Metascore,data.imdbRating);
end

genre = lower(data.Genre);
genre = strtok(genre,','); % most are multiple genres, only want primary

out = sprintf('%s is a %s %s-language %s film by %s starring %s. %s domestically. It was received %s',data.Title,data.Year,data.Language,genre,data.Director,stars,money,rating);
end