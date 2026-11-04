"""Publish the checked-in v4.49 package using a job-scoped GitHub Actions token."""
from pathlib import Path
import hashlib
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request

ROOT=Path(__file__).resolve().parent
REPOSITORY='Iron87ita/WarZone-Caucasus-Dynamic-Sector-Campaign'
API='https://api.github.com/repos/'+REPOSITORY

def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def verify_package():
    manifest=json.loads((ROOT/'manifest.json').read_text(encoding='utf-8'))
    assert manifest['repository']==REPOSITORY
    assert manifest['tag']=='v4.49'
    for asset in manifest['assets']:
        name=asset['name']
        assert Path(name).name==name
        assert sha256(ROOT/name)==asset['sha256'], 'Checksum mismatch: '+name
    print('Verified all',len(manifest['assets']),'release assets before publication.')
    return manifest

def publish():
    manifest=verify_package()
    if '--verify-only' in sys.argv:
        return
    assert os.environ.get('GITHUB_REPOSITORY')==REPOSITORY
    assert os.environ.get('GITHUB_REF')=='refs/heads/main'
    token=os.environ['GITHUB_TOKEN']

    def request(url,method='GET',data=None,content_type='application/json'):
        body=json.dumps(data).encode('utf-8') if isinstance(data,dict) else data
        headers={'Accept':'application/vnd.github+json','Authorization':'Bearer '+token,
            'X-GitHub-Api-Version':'2022-11-28','User-Agent':'WarZone-v4.49-Release-Publisher'}
        if body is not None:
            headers['Content-Type']=content_type
        req=urllib.request.Request(url,data=body,method=method,headers=headers)
        with urllib.request.urlopen(req,timeout=120) as response:
            raw=response.read()
            return json.loads(raw) if raw else None

    try:
        release=request(API+'/releases/tags/'+manifest['tag'])
        assert release['name']==manifest['title'], 'Existing release title differs; refusing to overwrite.'
    except urllib.error.HTTPError as error:
        if error.code!=404:
            raise
        release=request(API+'/releases',method='POST',data={
            'tag_name':manifest['tag'],'target_commitish':os.environ['GITHUB_SHA'],
            'name':manifest['title'],'body':(ROOT/'RELEASE_NOTES_v4.49.md').read_text(encoding='utf-8'),
            'draft':True,'prerelease':False})
        print('Created draft release:',release['id'])

    release_url=API+'/releases/'+str(release['id'])
    replacement=manifest.get('replacement')
    if replacement:
        assert release['id']==replacement['release_id'], 'Release identity changed; refusing replacement.'
    existing={asset['name']:asset for asset in request(release_url+'/assets?per_page=100')}
    expected={asset['name'] for asset in manifest['assets']}
    staged_names={a['name']+'.replacement-'+a['sha256'][:12] for a in manifest['assets']}
    assert set(existing).issubset(expected|staged_names), 'Unexpected assets on existing release; refusing to modify it.'
    staged={}
    # Upload and verify all replacements before touching any published asset.
    for asset in manifest['assets']:
        name=asset['name']
        uploaded=existing.get(name)
        if uploaded and uploaded.get('digest')=='sha256:'+asset['sha256']:
            continue
        if not release['draft']:
            assert replacement, 'Published release replacement was not explicitly authorized.'
            if uploaded:
                assert uploaded.get('digest')==replacement['expected_assets'].get(name), 'Published asset changed concurrently: '+name
        stage_name=name+'.replacement-'+asset['sha256'][:12]
        ready=existing.get(stage_name)
        if ready is None:
            url=release['upload_url'].split('{',1)[0]+'?'+urllib.parse.urlencode({'name':stage_name})
            content_type='application/octet-stream' if name.endswith('.miz') else 'text/plain; charset=utf-8'
            ready=request(url,method='POST',data=(ROOT/name).read_bytes(),content_type=content_type)
        assert ready['state']=='uploaded', 'Upload incomplete: '+name
        assert ready.get('digest')=='sha256:'+asset['sha256'], 'Staged asset digest mismatch: '+name
        staged[name]=ready
        print('Verified staged asset:',name,ready['size'],'bytes')

    for name,ready in staged.items():
        current={a['name']:a for a in request(release_url+'/assets?per_page=100')}.get(name)
        if current:
            assert replacement and current.get('digest')==replacement['expected_assets'].get(name), 'Replacement lease changed: '+name
            request(API+'/releases/assets/'+str(current['id']),method='DELETE')
        renamed=request(API+'/releases/assets/'+str(ready['id']),method='PATCH',data={'name':name})
        assert renamed['name']==name and renamed['state']=='uploaded'
        print('Installed verified replacement:',name)

    release=request(release_url,method='PATCH',data={
        'name':manifest['title'],
        'body':(ROOT/'RELEASE_NOTES_v4.49.md').read_text(encoding='utf-8')+
            '\nRevision source: https://github.com/'+REPOSITORY+'/commit/'+os.environ['GITHUB_SHA']+'\n',
        'make_latest':'true'})

    if release['draft']:
        release=request(release_url,method='PATCH',data={'draft':False,'prerelease':False,'make_latest':'true'})
    assert not release['draft'] and release['tag_name']==manifest['tag']
    latest=request(API+'/releases/latest')
    assert latest['id']==release['id'], 'New release is not marked latest.'
    # Verify the actual public mission download against the local release manifest.
    public_assets={asset['name']:asset for asset in request(release_url+'/assets?per_page=100')}
    mission=next(asset for asset in manifest['assets'] if asset['name'].endswith('.miz'))
    download_url=public_assets[mission['name']]['browser_download_url']
    with urllib.request.urlopen(urllib.request.Request(download_url,headers={'User-Agent':'WarZone-Release-Verification'}),timeout=120) as response:
        downloaded=hashlib.sha256(response.read()).hexdigest()
    assert downloaded==mission['sha256'], 'Public download checksum mismatch.'
    print('PUBLISHED:',release['html_url'])
    print('Public mission download verified:',downloaded)
    summary=os.environ.get('GITHUB_STEP_SUMMARY')
    if summary:
        with open(summary,'a',encoding='utf-8') as output:
            output.write('## WarZone Caucasus v4.49 published\n\n['+release['name']+']('+release['html_url']+')\n\n'
                'All five release assets passed SHA-256 verification. Public mission download verified.\n')

if __name__=='__main__':
    publish()

