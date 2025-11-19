# https://developers.google.com/people/api/rest/v1/people/get
function people.get -d "Google API: people.get"
    if test ( count $argv ) -eq 0
        printf "usage: %s me|user_id [access_token]\n" (status current-command)
        return
    end
    # example 112077979967606528699
    set userId "$argv[1]"
    set personFields addresses ageRanges biographies birthdays braggingRights coverPhotos emailAddresses events genders imClients interests locales memberships metadata names nicknames occupations organizations phoneNumbers photos relations relationshipInterests relationshipStatuses residences sipAddresses skills taglines urls userDefined
    set qs "?personFields="(string join "," $personFields)
    if test ( count $argv ) -gt 1
        set qs $qs"&access_token=$argv[2]"
    end
    set url "https://people.googleapis.com/v1/people/$userId$qs"
    echo "# $url"
    curl -sS $url
end
