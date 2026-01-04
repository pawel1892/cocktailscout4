import React from 'react'
import ShoutboxEntry from './shoutbox/shoutboxEntry';
import ShoutboxForm from './shoutbox/shoutboxForm';

export default class Shoutbox extends React.Component {
    constructor(props) {
        super(props);
        this.state = {
            shoutboxEntries: [],
            postingNewEntry: false
        };

        this.handleNewShoutboxEntry = this.handleNewShoutboxEntry.bind(this);
        this.refreshContent = this.refreshContent.bind(this);

        this.refreshContent()
    }

    handleNewShoutboxEntry(shout) {
        const csrfToken = document.querySelector('meta[name="csrf-token"]').content

        this.setState({postingNewEntry: true})

        fetch('/api/shoutbox_entries', {
            method: 'POST',
            headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
                'X-CSRF-Token': csrfToken
            },
            body: JSON.stringify({shoutbox_entry: {content: shout}}),
            credentials: 'same-origin'
        })
            .then((response) => response.json())
            .then((responseData) => {
                this.setState({shoutboxEntries: responseData, postingNewEntry: false})
            })
            .catch((error) => {
                this.setState({postingNewEntry: false})
                console.log(error)
            })
    }

    refreshContent() {
        fetch('/api/shoutbox_entries', {
            method: 'GET',
            headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json'
            }
        })
            .then((response) => response.json())
            .then((responseData) => {
                this.setState({shoutboxEntries: responseData})
            })
            .catch((error) => {
                console.log(error)
            })
    }

    render() {
        const shoutboxEntriesRows = this.state.shoutboxEntries.map((shoutboxEntry) =>
            <ShoutboxEntry key={shoutboxEntry.id}
                           content={shoutboxEntry.content}
                           login={shoutboxEntry.user.login}
                           profile_link={shoutboxEntry.user.profile_link}
                           timeAgo={shoutboxEntry.time_ago}
            />
        );

        return (
            <div className={'shoutbox'} id='shoutbox'>
                <table>
                    <tbody>
                        {shoutboxEntriesRows}
                    </tbody>
                </table>
                <ShoutboxForm
                    onShoutboxEntrySubmit={this.handleNewShoutboxEntry}
                    loggedIn={this.props.loggedIn}
                    postingNewEntry={this.state.postingNewEntry}
                />
            </div>
        );
    }
}
