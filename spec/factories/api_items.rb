# frozen_string_literal: true
FactoryBot.define do
  factory :post_item, class: Hash do
    skip_create

    token { 'mock_token' }

    metadata do
      {
        resourceType: 'Dataset',
        title: 'Findings from NSF Study',
        creators: [
          {
            creatorType: 'author',
            firstName: 'John',
            lastName: 'Doe'
          },
          {
            creatorType: 'seriesEditor',
            firstName: 'Rafael',
            lastName: 'Nadal'
          },
          {
            creatorType: 'inventor',
            name: 'Babs McGee'
          },
          {
            creatorType: 'contributor',
            name: 'Jane Doeski'
          }
        ],
        description: 'This was funded by the NSF in 2013',
        publisher: 'National Science Foundation',
        dateCreated: '2014-11-02T14:24:64Z',
        basedNear: 'Paris, France',
        identifier: 'isbn:1234567890',
        url: 'http://example.org/nsf/2013/datasets/',
        language: 'English--New Jerseyan',
        license: 'http://creativecommons.org/licenses/by-sa/3.0/us/',
        tags: [
          'datasets',
          'nsf',
          'stuff'
        ]
      }
    end

    file do
      {
        base64: 'YXJraXZvCg==',
        md5: 'f03313ded2feb96f0a641b8eb098aae0',
        filename: 'file.txt',
        contentType: 'text/plain'
      }
    end

    initialize_with { attributes }
  end

  factory :put_item, class: Hash, parent: :post_item do
    metadata do
      {
        resourceType: 'Article',
        title: 'THE REAL FINDINGS',
        creators: [
          {
            creatorType: 'author',
            firstName: 'John',
            lastName: 'Doe'
          },
          {
            creatorType: 'inventor',
            name: 'Babs McGee'
          }
        ],
        license: 'http://creativecommons.org/licenses/by-sa/3.0/us/',
        tags: [
          'datasets'
        ]
      }
    end

    file do
      {
        base64: 'IyBIRUFERVIKClRoaXMgaXMgYSBwYXJhZ3JhcGghCg==',
        md5: '3923077bb477097b8496dbcff5fa44b3',
        filename: 'replaced.md',
        contentType: 'text/x-markdown'
      }
    end
  end
end
