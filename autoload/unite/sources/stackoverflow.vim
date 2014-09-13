let s:save_cpo = &cpo
set cpo&vim

let g:unite_source_stackoverflow_search_limit = get(g:, 'unite_source_stackoverflow_search_limit', 100)

let s:source = {
            \ 'name' : 'stackoverflow',
            \ 'description' : 'Search stackoverflow.com',
            \ 'default_kind' : 'uri',
            \ 'default_action' : {'uri' : 'start'},
            \ 'hooks' : {},
            \ }

function! unite#sources#stackoverflow#define()
    return has('ruby') ? s:source : {}
endfunction

function! s:source.hooks.on_init(args, context)
    let a:context.stackoverflow__input = input("keywords? ")
endfunction

function! s:source.gather_candidates(args, context)

    let candidates = []

ruby << EOF
    require 'rubygems' if RUBY_VERSION < "1.9"
    require 'json'
    require 'net/http'

    module StackOverflow
    module API extend self

        def search(query, type)
            api_get("/2.0/similar?order=desc&sort=votes&#{type}=#{URI::encode query}&site=stackoverflow&filter=!9Tk5iz1Gf")
        end

        private

        def api_get(path)
            url = "https://api.stackexchange.com" + path
            u = URI.parse(url)
            Net::HTTP.start(u.host, u.port, :use_ssl => true) do |http|
                response = http.get(u.request_uri)
                return JSON(response.body)['items']
            end
        end

    end
    end

    StackOverflow::API::search_title(VIM::evaluate('a:context.stackoverflow__input'), "intitle").each do |item|
        VIM::evaluate "add(candidates, {'word' : \"#{item['title']}\", 'action__uri' : \"#{item['link']}\"})"
    end
EOF

    return candidates
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
